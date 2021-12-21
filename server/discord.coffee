'use strict'

import { DiscordBot, FailDiscordBot } from './imports/discord.coffee'

# helper functions to perform Google Drive operations

# Intialize APIs and load rootFolder
if Meteor.isAppTest
  share.discordBot = new FailDiscordBot
  return
Promise.await do ->
  try
    if Meteor.settings.discordServerName? && Meteor.settings.discordToken?
      share.discordBot = new DiscordBot(Meteor.settings.discordServerName, 
        Meteor.settings.discordSwarmChannel, Meteor.settings.discordToken)
    else
      share.discordBot = new FailDiscordBot
      console.warn "Please provide a discord server name and bot token. Discord integration disabled."
  catch error
    console.warn "Error trying to set up DAPHNE:", error
    console.warn "Discord integration disabled."
    share.discordBot = new FailDiscordBot
