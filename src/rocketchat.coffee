try
	  {Robot,Adapter,TextMessage,User} = require 'hubot'
catch
	  prequire = require('parent-require')
	  {Robot,Adapter,TextMessage,User} = prequire 'hubot'
Q = require 'q'
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
			@robot.logger.info RocketChatRoom

			rooms = RocketChatRoom.split(',')
			# @robot.logger.info JSON.stringify(rooms)

			@chatdriver.login(RocketChatUser, RocketChatPassword)
				.then(
					(userid) =>
						@robot.logger.info "Successfully Logged In"
						joinrooms = []
						subs = []
						for room in rooms
							do(room) =>
								joinrooms.push @chatdriver.joinRoom(userid, RocketChatUser, room)

						Q.all(joinrooms)
							.then(
								(res) =>
									@robot.logger.info "all rooms joined"
									for result, idx in res
										@robot.logger.info "Successfully joined room: #{rooms[idx]}"
										subs.push @chatdriver.prepMeteorSubscriptions({uid: userid, roomid: rooms[idx]})	

									Q.all(subs)
										.then(
											(results) => 
												@robot.logger.info "all subscriptions ready"
												for result, idx in results
													@robot.logger.info "Successfully subscribed to room: #{rooms[idx]}"


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
											(err) =>
												@robot.logger.error "Unable to subscribe: #{err} Reason: #{err.reason}"
										)

								(err) =>
									@robot.logger.error "Unable to Join room: #{err} Reason: #{err.reason}"
							)


					(err) =>
						@robot.logger.error "Unable to Login: #{err} Reason: #{err.reason}"
						@robot.logger.error "If joining GENERAL please make sure its using all caps"
				)
								
				@emit 'connected'
				
	send: (envelope, strings...) =>
			@chatdriver.sendMessage(str, envelope.room) for str in strings

	reply: (envelope, strings...) =>
			@robot.logger.info "reply"
			strings = strings.map (s) -> "@#{envelope.user.name} #{s}"
			@send envelope, strings...

exports.use = (robot) ->
	  new RocketChatBotAdapter robot
