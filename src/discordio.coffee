# Description:
#   A nominal Discord adapter.
{Adapter, TextMessage, User} = require.main.require 'hubot'
{Client} = require.main.require 'discord.io'

class DiscordIOAdapter extends Adapter

  run: ->
    unless process.env.HUBOT_DISCORDIO_TOKEN
      return @robot.logger.error("hubot-discordio cannot work without HUBOT_DISCORDIO_TOKEN; not connecting.")

    @client = new Client({
      token: process.env.HUBOT_DISCORDIO_TOKEN
    })
    @client.on('ready', @_clientReady)
    @client.on('message', @_clientMessage)
    @client.on('guildCreate', @_clientGuildCreate)
    @client.on('disconnect', @_clientDisconnect)
    #@client.on('any', @_clientSpamAll)

    @client.connect()

  send: (envelope, strings...) ->
    for s in strings
      @client.sendMessage(to: envelope.room, message: s)

  reply: (envelope, strings...) ->
    @send(envelope, strings...)

  close: ->
    @robot.logger.info("Discord disconnecting")
    @client.disconnect()

  _clientReady: (event) =>
    @robot.logger.info("Discord connected")
    @emit "connected"

  _clientMessage: (user, userID, channelID, message, event) =>
    if userID == @client.internals.oauth.id
      return

    if @client.directMessages[channelID]
      message = "#{@robot.name} #{message}"

    u = new User(userID, name: user.username, room: channelID)
    @robot.receive new TextMessage(u, message, event.d.id)

  _clientGuildCreate: (server, event) =>
    for c in server.channels
      @robot.logger.info(c)

  _clientDisconnect: (errorMessage, code) =>
    @robot.logger.info("Discord disconnected: #{errorMessage}")
    @emit 'error', error_message

  _clientSpamAll: (all...) =>
    @client.directMessages
    @robot.logger.info(all)
    if all[0].d?
      @robot.logger.info(all[0].d.author)

exports.use = (robot) ->
  new DiscordIOAdapter robot
