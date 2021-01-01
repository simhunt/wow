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
VOICE_CHANNEL_DELETE_DELAY = 60 * S_TO_MS
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
          return
          console.warn "Rate limited; Will return after #{DELAYS[ix]}ms"
          await delay DELAYS[ix]
          ix++

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
        (!query?.round? || query.round == @channelIdToRoundName.channel.id))
      result.push(channel)
  )
  return result
  
getCategoriesForRound = (name) ->
  console.log('getCategoriesForRound')
  if roundNameToCategories[name]?
    return roundNameToCategories[name]
  return []

getNonfullCategoryForRound = (guild, roundName) ->
  console.log('getNonfullCategoryForRound')
  result = null
  categories = await getCategoriesForRound(roundName)
  console.log(categories)
  for category in categories
    console.log(category)
    if category.children.size < MAX_CHANNELS_IN_CATEGORY
      result = category
  if result?
    console.log('found existing category that works', result)
  return result if result?
  # We need to make a new channel
  console.log('making a new channel')
  newCategory = null
  continuationNumber = categories.length + 1
  try
    if continuationNumber <= 1
      console.log('make the first category for this round')
      newCategoryName = roundName
      newCategory = await apiThrottle guild.channels, 'create', newCategoryName, {type: "category"}
      roundNameToCategories[roundName] = [newCategory]
      console.log(roundNameToCategories)
      channelIdToRoundName[newCategory.id] = roundName
    else 
      console.log('make a continuation category for this round')
      newCategoryName = "#{roundName}-#{continuationNumber}"
      newCategory = await apiThrottle guild.channels, 'create', newCategoryName, {type: "category"}
      roundNameToCategories[roundName].push(newCategory)
      channelIdToRoundName[newCategory.id] = roundName
    return newCategory
  catch error
    console.warn error

newVoiceChannel = (guild, roundName, name) -> 
  console.log("new voice channel for round " + roundName + " with name " + name)
  self = this
  mutex.acquire().then((release) ->
    if getChannels(guild, {type: "voice", name: name, round: roundName}).length > 0
      console.warn "Voice channel #{name} in #{roundName} already exists."
      return
    categoryChannel = await getNonfullCategoryForRound(guild, roundName)
    newChannel = await apiThrottle guild.channels, 'create', name, {type: "voice", parent: categoryChannel}
    channelIdToRoundName[newChannel.id] = roundName
    release()
  )
  'ok'

# identifier is an object containing `name` and/or `channel` 
# (where `channel` takes precedence)
deleteChannel = (identifier, guild, type) ->
  if identifier.channel? 
    channel = identifier.channel 
  else 
    channel = getChannels(guild, {type: type, name: identifier.name})?[0]
  # Perform deletion of channel in Discord
  console.log('deleting channel ' + channel)
  await apiThrottle channel, 'delete', "Puzzle solved!"
  # Maintain rep invariants
  roundName = channelIdToRoundName[channel.id]
  unless roundName?
    return 'ok'
  categories = await getCategoriesForRound(roundName)
  for category in categories
    if category.children.size == 0
      await apiThrottle category, 'delete'
      break
  categories = await getCategoriesForRound(roundName) 
  if categories.length == 0
    delete roundNameToCategories[roundName]
  else
    if categories[0].name != roundName
      await apiThrottle categories[0], 'setName', roundName
    for i in [1...categories.length]
      if categories[i].name != "#{roundName}-#{i+1}"
        await apiThrottle categories[0], 'setName', roundName
  delete channelIdToRoundName[channel.id]
  'ok'

deleteVoiceChannelWithTimeout = (guild, name) ->
  channel = null
  mutex.acquire().then((release) ->
    channel = getChannels(guild, {type: 'voice', name: name})?[0]
    if channel?
      await apiThrottle channel, 'setName', "#{GREEN_CHECK}#{name}"
      release()
      deleteAfterTimeout = () -> 
        mutex.acquire().then((release) ->
          await deleteChannel({channel: channel}, guild, 'voice')
          release()
        )
      setTimeout deleteAfterTimeout, VOICE_CHANNEL_DELETE_DELAY
    else
      console.warn "Voice channel with #{name} does not exist. Skipping deletion."
  )
  'ok'

purge = (guild) ->
  mutex.acquire().then((release) ->
    channels = getChannels(guild)
    for channel in channels
      await deleteChannel({channel: channel}, guild, channel)
    release()
  )
  roundNameToCategories = {}
  channelIdToRoundName = {}
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
        console.log(channel, snowflake)
        if channel.type == 'category'
          dashIndex = channel.name.lastIndexOf('-')
          if dashIndex == -1
            baseName = channel.name
          else
            continuationNumber = channel.name.substring(dashIndex+1)
            if continuationNumber.isNan()
              baseName = channel.name
            else
              baseName = channel.name.substring(0, dashIndex)
          if roundNameToCategories[baseName]?
            roundNameToCategories[baseName].push(channel)
          else
            roundNameToCategories[baseName] = [channel]
          channelIdToRoundName[channel.id] = baseName
      )
      roundNameToCategories.forEach(channelList -> channelList.sort())
      # Associate each non-category channel to a round
      self.guild.cache.forEach((channel, snowflake) ->
        if channel.type != 'category'
          if channel.parent?
            channelIdToRoundName[channel.id] = channelIdToRoundName[channel.parent.id]
      )
    )
    @client.login(discordToken)

  newVoiceChannel: (roundName, name) -> newVoiceChannel(@guild, roundName, name)
  deleteVoiceChannelWithTimeout: (name) -> deleteVoiceChannelWithTimeout(@guild, name)
  purge: -> purge(@guild)
  
        
# generate functions
skip = (type) -> -> console.warn "Skipping Discord operation:", type
export class FailDiscordBot
  newVoiceChannel: skip 'newVoiceChannel'
  deleteVoiceChannelWithTimeout: skip 'deleteVoiceChannelWithTimeout'
  purge: skip 'purge'