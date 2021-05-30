'use strict'

# Imports
Discord = require('discord.js');
import {Mutex, MutexInterface, Semaphore, SemaphoreInterface, withTimeout} from 'async-mutex';
import delay from 'delay'
import emojify from './emoji.coffee'

# Constants

# Things that are true no matter what
S_TO_MS = 1000
GREEN_CHECK = emojify(":white_check_mark:")
MAX_CHANNELS_IN_CATEGORY = 50

# Parameters (can be changed according to preference)
VOICE_CHANNEL_DELETE_DELAY = 10 * S_TO_MS
DELAYS = [100, 250, 500, 1000, 2000, 5000, 10000]

# Ensure mutual exclusion
mutex = new Mutex()

# Helper method to handle rate limiting
apiThrottle = (base, name, params, options) ->
  ix = 0
  Promise.await do ->
    loop
      try
        result = await (base[name](params, options))
        return result if result?
      catch error
        console.warn error
        if ix >= DELAYS.length
          throw error
        if error.retry_after?
          console.warn "Rate limited; Will return after #{error.retry_after}ms"
          await delay error.retry_after
          ix++
        else
          throw error

# Mutex-wrapping function
doWithLock = (synchBlock, errorMsg) ->
  mutex.acquire().then((release) ->
    try
      await synchBlock()
    catch
      console.warn errorMsg
    finally
      release() # Release the lock no matter what -- important!
  ).catch((error) -> 
    console.warn errorMsg
  )

# Maps round name to list of categories (1-to-many)
roundNameToCategories = {}
# Maps channel ID to round name (1-to-1)
channelIdToRoundName = {}

# Function definitions

# query has type, name, round
getChannels = (guild, query, channelCollection) ->
  # Use the entire set of channels if no Collection is specified
  channelCollection = guild.channels.cache unless channelCollection?
  result = []
  channelCollection.forEach((channel, snowflake) ->
    if ((!query?.type? || query.type == channel.type) && 
        (!query?.name? || query.name == channel.name) &&
        (!query?.round? || query.round == channelIdToRoundName[channel.id]))
      result.push(channel)
  )
  return result
  
getCategoriesForRound = (name) ->
  if roundNameToCategories[name]?
    return roundNameToCategories[name]
  return []

getNonfullCategoryForRound = (guild, roundName) ->
  result = null
  categories = await getCategoriesForRound(roundName)
  for category in categories
    if category.children.size < MAX_CHANNELS_IN_CATEGORY
      result = category
  return result if result?
  # We need to make a new channel
  newCategory = null
  continuationNumber = categories.length + 1
  try
    if continuationNumber <= 1
      newCategoryName = roundName
      newCategory = await apiThrottle guild.channels, 'create', newCategoryName, {type: "category"}
      roundNameToCategories[roundName] = [newCategory]
      channelIdToRoundName[newCategory.id] = roundName
    else 
      newCategoryName = "#{roundName}-#{continuationNumber}"
      newCategory = await apiThrottle guild.channels, 'create', newCategoryName, {type: "category"}
      roundNameToCategories[roundName].push(newCategory)
      channelIdToRoundName[newCategory.id] = roundName
    return newCategory
  catch error
    console.warn error

# 'public'
# adds a voice channel with name `name` to the round with name `roundName` in the guild `guild`
newVoiceChannel = (guild, roundName, name) -> 
  self = this
  synchBlock = ->
    if getChannels(guild, {type: "voice", name: name, round: roundName}).length > 0
      console.warn "Voice channel #{name} in #{roundName} already exists."
      return
    categoryChannel = await getNonfullCategoryForRound(guild, roundName)
    newChannel = await apiThrottle guild.channels, 'create', name, {type: "voice", parent: categoryChannel}
    channelIdToRoundName[newChannel.id] = roundName
  errorMsg = "Failed to create voice channel $#{name} for round #{roundName}"
  doWithLock synchBlock, errorMsg
  'ok'

# 'private' (aka helper method - please hold mutex before calling)
# identifier is an object containing `name` and/or `channel` 
# (where `channel` takes precedence)
deleteChannel = (identifier, guild, type) ->
  if identifier.channel? 
    channel = identifier.channel 
  else 
    channel = getChannels(guild, {type: type, name: identifier.name})?[0]
  if channel?
    # Perform deletion of channel in Discord
    await apiThrottle channel, 'delete', "Puzzle solved!"
    # Maintain rep invariants
    roundName = channelIdToRoundName[channel.id]
    unless roundName?
      return 'ok'
    # This channel ID no longer exists, so it doesn't have a round.
    delete channelIdToRoundName[channel.id]
    await handleEmptyCategories(guild, roundName)
  'ok'
  

# 'private' helper method - please hold lock before calling
handleEmptyCategories = (guild, affectedRound) -> 
  # First, iterate through all the current categories;
  # Delete the Discord categories that no longer have children,
  # and delete them from the CoffeScript categories map as well.
  oldCategories = await getCategoriesForRound(affectedRound)
  newCategories = []
  for category in oldCategories
    if category.children.size == 0
      await apiThrottle category, 'delete'
      delete channelIdToRoundName[category.id]
    else
      newCategories.push(category) # copy channel references
  if newCategories.length == 0
    delete roundNameToCategories[affectedRound]
  else
    # Rename the categories that still exist so that their names are
    # affectedRound, affectedRound-2, affectedRound-3... with no gaps
    if newCategories[0].name != affectedRound
      await apiThrottle newCategories[0], 'setName', affectedRound
    for i in [1...newCategories.length]
      if newCategories[i].name != "#{affectedRound}-#{i+1}"
        await apiThrottle newCategories[i], 'setName', "#{affectedRound}-#{i+1}"
    roundNameToCategories[affectedRound] = newCategories # change the global storage
  'ok'

# 'public'
# deletes the channel with name `name` from the guild `guild`
deleteVoiceChannel = (guild, name) ->
  synchBlock = ->
    await deleteChannel({name: name}, guild, 'voice')
  errorMsg = console.warn 'Failed to delete channel ' + name
  doWithLock synchBlock, errorMsg
  'ok'

# 'public'
# deletes the channel with name `name` from the guild `guild`
deleteVoiceChannelWithTimeout = (guild, name) ->
  errorMsg = 'Voice channel with #{name} does not exist. Skipping deletion.'
  renameAndWait = ->
    channel = null
    channel = getChannels(guild, {type: 'voice', name: name})?[0]
    if channel?
      await apiThrottle channel, 'setName', "#{GREEN_CHECK}     #{name}"

      # Now that the channel has been renamed, set up the delete
      deleteAfterTimeout = () -> 
        await deleteChannel({channel: channel}, guild, 'voice')

      lockedDelete = -> doWithLock deleteAfterTimeout, errorMsg

      # Wait a bit before calling lockedDelete
      setTimeout lockedDelete, VOICE_CHANNEL_DELETE_DELAY
  
  doWithLock renameAndWait, errorMsg

  'ok'

# 'public'
# renames a channel
rename = (guild, oldName, newName) ->
  # We don't have to worry about duplication; that's handled before the call to this function in model.coffee
  synchBlock ->
    newRoundNameToCategories = {}
    newChannelIdToRoundName = {}
    for roundName, categories of roundNameToCategories
      # If the thing that is being changed is a round, keep the same category channels (we'll rename them at the end of the function)
      # but update the name of the key.
      if roundName == oldName
        newRoundNameToCategories[newName] = categories
      else
        # The round is not changing, so the round name -> category channel mapping does not need to change.
        newRoundNameToCategories[roundName] = categories
    # Also replace references to the round in the channel ID -> round name mapping.
    for channelId, roundName of channelIdToRoundName
      newChannelIdToRoundName[channelId] = roundName == oldName ? roundName : newName

    # Now make sure that channels in Discord are being named appropriately
    for channel in getChannels(guild)
      name = channel.name
      if name == oldName or name.search("#{oldName}-") != -1 # assume that "oldName-" only appears in category channels "within" rounds.
        await apiThrottle channel, 'setName', name.replace(oldName, newName)
    roundNameToCategories = newRoundNameToCategories
    channelIdToRoundName = newChannelIdToRoundName
  doWithLock synchBlock, "Could not rename channel #{oldName}"
  'ok'

# 'public'
# purges all channels in a guild
# ONLY MEANT FOR DEVELPMENT / DEBUGGING. VERY DANGEROUS.
purge = (guild) ->
  synchBlock ->
    channels = getChannels(guild)
    for channel in channels
      await deleteChannel({channel: channel}, guild, channel)
    roundNameToCategories = {}
    channelIdToRoundName = {}
  doWithLock synchBlock, ''
  'ok'

export class DiscordBot
  constructor: (guildName, discordToken) ->
    @discordToken = discordToken
    @client = new Discord.Client()
    # Need to be able to access 'this' from inside the onReady function
    self = this
    @client.on('ready', ->
      @guilds.cache.forEach (guild) ->
        if guild.name == guildName 
          self.guild = guild
          console.log("DAPHNE is watching #{guildName}!")
      unless self.guild?
        console.warn "DAPHNE is not added to #{guildName}!"
        return
      # self.purge()
      # Map each round to its category channels
      # and map each category channel to its round
      self.guild.channels.cache.forEach((channel, snowflake) ->
        if channel.type == 'category'
          dashIndex = channel.name.lastIndexOf('-')
          if dashIndex == -1
            baseName = channel.name
          else
            continuationNumber = channel.name.substring(dashIndex+1)
            if isNaN(continuationNumber)
              baseName = channel.name
            else
              baseName = channel.name.substring(0, dashIndex)
          if roundNameToCategories[baseName]?
            roundNameToCategories[baseName].push(channel)
          else
            roundNameToCategories[baseName] = [channel]
          channelIdToRoundName[channel.id] = baseName
      )
      for roundName, channelList of roundNameToCategories
        channelList.sort()
      # Associate each non-category channel to a round
      self.guild.cache?.forEach((channel, snowflake) ->
        if channel.type != 'category'
          if channel.parent?
            channelIdToRoundName[channel.id] = channelIdToRoundName[channel.parent.id]
      )
    )
    @client.login(discordToken)

  newVoiceChannel: (roundName, name) -> newVoiceChannel(@guild, roundName, name)
  deleteVoiceChannel: (name) -> deleteVoiceChannel(@guild, name)
  deleteVoiceChannelWithTimeout: (name) -> deleteVoiceChannelWithTimeout(@guild, name)
  rename: (oldName, newName) -> rename(@guild, oldName, newName)
  purge: -> purge(@guild)
  
        
# generate functions
skip = (type) -> -> console.warn "Skipping Discord operation:", type
export class FailDiscordBot
  newVoiceChannel: skip 'newVoiceChannel'
  deleteVoiceChannel: skip 'deleteChannel'
  deleteVoiceChannelWithTimeout: skip 'deleteVoiceChannelWithTimeout'
  rename: skip 'rename'
  purge: skip 'purge'