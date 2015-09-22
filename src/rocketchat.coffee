try
      {Robot,Adapter,TextMessage,User} = require 'hubot'
catch
      prequire = require('parent-require')
      {Robot,Adapter,TextMessage,User} = prequire 'hubot'

Chatdriver = require './rocketchat_driver'

RocketChatURL = process.env.ROCKETCHAT_URL or "localhost:3000"
RocketChatRoom = process.env.ROCKETCHAT_ROOM or "GENERAL"
RocketChatUser = process.env.ROCKETCHAT_USER or "hubot"
RocketChatPassword = process.env.ROCKETCHAT_PASSWORD or "password"

class RocketChatBotAdapter extends Adapter

    run: =>
        @robot.logger.info "Starting Rocketchat adapter..."

        @robot.logger.info "Once connected to rooms I will respond to the name: #{@robot.name}"

        @robot.logger.warning "No services ROCKETCHAT_URL provided to Hubot, using #{RocketChatURL}" unless process.env.ROCKETCHAT_URL
        @robot.logger.warning "No services ROCKETCHAT_ROOM provided to Hubot, using #{RocketChatRoom}" unless process.env.ROCKETCHAT_ROOM
        @robot.logger.warning "No services ROCKETCHAT_USER provided to Hubot, using #{RocketChatUser}" unless process.env.ROCKETCHAT_USER
        return @robot.logger.error "No services ROCKETCHAT_PASSWORD provided to Hubot" unless RocketChatPassword

        @lastts = new Date()

        @robot.logger.info "Connecting To: #{RocketChatURL}"

        @chatdriver = new Chatdriver RocketChatURL, @robot.logger, =>
            @robot.logger.info "Successfully Connected!"

            rooms = RocketChatRoom.split(',')

            @chatdriver.login(RocketChatUser, RocketChatPassword)
                .then (userid) =>
                    @robot.logger.info "Successfully Logged In"

                    for room in rooms
                        do(room) =>
                            @chatdriver.joinRoom userid, RocketChatUser, room
                                .then (result) =>
                                    @robot.logger.info "Successfully Joined Room: #{room}"
                                    @chatdriver.prepMeteorSubscriptions({uid: userid, roomid: room})
                                        .then (arg) =>
                                            @robot.logger.info "Subscription Ready"
                                            @chatdriver.setupReactiveMessageList (newmsg) =>
                                                if newmsg.u._id isnt userid
                                                    curts = new Date(newmsg.ts.$date)
                                                    @robot.logger.info "Message receive callback id " + newmsg._id + " ts " + curts
                                                    @robot.logger.info "[Incoming] #{newmsg.u.username}: #{newmsg.msg}"

                                                    if curts > @lastts
                                                        @lastts = curts
                                                        user = @robot.brain.userForId newmsg.u._id, name: newmsg.u.username, room: newmsg.rid
                                                        text = new TextMessage(user, newmsg.msg, newmsg._id)

                                                        @robot.receive text
                                                        @robot.logger.info "Message sent to hubot brain."
                                        .catch (err) =>
                                            @robot.logger.error "Error subscribing", err

                                .catch (err) =>
                                    @robot.logger.error "Unable to Join Room: #{room} Reason: #{err.reason}"


                    @emit 'connected'
                .catch (err) =>
                    @robot.logger.error "Unable to Login. Reason: #{err.reason}"

      send: (envelope, strings...) =>
            @chatdriver.sendMessage(str, envelope.room) for str in strings

      reply: (envelope, strings...) =>
            @robot.logger.info "reply"
            strings = strings.map (s) -> "@#{envelope.user.name} #{s}"
            @send envelope, strings...

exports.use = (robot) ->
      new RocketChatBotAdapter robot
