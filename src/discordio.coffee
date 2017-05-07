# Description:
#   A nominal Discord adapter.
{Adapter, TextMessage, User} = require.main.require 'hubot'
{Client} = require.main.require 'discord.io'

class DiscordIOAdapter extends Adapter

  run: ->
    unless process.env.HUBOT_DISCORDIO_TOKEN
      return @robot.logger.error("hubot-discordio loaded without HUBOT_DISCORDIO_TOKEN; not connecting.")

    @client = new Client({
      token: process.env.HUBOT_DISCORDIO_TOKEN
    })
    @client.on('ready', @_clientReady)
    @client.on('message', @_clientMessage)
    @client.on('disconnect', @_clientDisconnect)

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
    @emit("connected")

  _clientMessage: (user, userID, channelID, message, event) =>
    if userID == @client.id
      return

    if @client.directMessages[channelID]
      message = "#{@robot.name} #{message}"

    u = new User(userID, name: user.username, room: channelID)
    @robot.receive(new TextMessage(u, message, event.d.id))

  _clientDisconnect: (errorMessage, code) =>
    @emit('error', "Discord disconnected: #{errorMessage} (#{code})")

exports.use = (robot) ->
  new DiscordIOAdapter(robot)
