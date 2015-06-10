{Robot, Adapter, TextMessage} = require 'hubot'
RocketChatDriver = require './rocketchat_driver'

class RocketChatBotAdapter extends Adapter

  @MAX_MESSAGE_LENGTH: 4000
  @MIN_MESSAGE_LENGTH: 1

  constructor: (robot) ->
    @robot = robot

  run: =>

    @RocketChatURL = process.env.ROCKETCHAT_URL or "localhost:3000"
    @RocketChatUser = process.env.ROCKETCHAT_USER or "hubot"
    @RocketChatPassword = process.env.ROCKETCHAT_PASSWORD or "abc123"
    @RocketChatRoom = process.env.ROCKETCHAT_ROOM or "57om6EQCcFami9wuT"

    return @robot.logger.error "No services URL provided to Hubot" unless @RocketChatURL
    return @robot.logger.error "No services User provided to Hubot" unless @RocketChatUser
    return @robot.logger.error "No services Password provided to Hubot" unless @RocketChatPassword

    @robot.logger.info "RocketChatBot Running"

    @chatdriver = new RocketChatDriver @RocketChatURL, @robot.logger
    @chatdriver.login(@RocketChatUser, @RocketChatPassword).then (userid) =>
      @robot.logger.info "RocketChatBot Logged-in"
      @chatdriver.joinRoom userid, @RocketChatUser, @RocketChatRoom
      @chatdriver.prepMeteorSubscriptions({uid: userid, roomid: @RocketChatRoom}).then (arg) =>
        @robot.logger.info "RocketChatBot Subscription Ready"
        @chatdriver.setupReactiveMessageList (message) =>
          @robot.logger.info "RocketChatBot Message Receive Callback"
          user = @robot.brain.userForId message.u._id, name: message.u.username, room: message.rid
          text = new TextMessage(user, message.msg, message._id)
          @robot.receive(text)
    @emit 'connected'

  send: (envelope, strings...) =>
    @robot.logger.info "send msg"
    @chatdriver.sendMessage(str, envelope.room) for str in strings

  reply: (envelope, strings...) =>
    @robot.logger.info "reply"
    strings = strings.map (s) -> "@#{envelope.user.name}: #{s}"
    @send envelope, strings...

exports.use = (robot) ->
  new RocketChatBotAdapter robot
