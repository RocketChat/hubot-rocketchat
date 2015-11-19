try
	  {Robot,Adapter,TextMessage, EnterMessage, User} = require 'hubot'
catch
	  prequire = require('parent-require')
	  {Robot,Adapter,TextMessage, EnterMessage, User} = prequire 'hubot'
Q = require 'q'
Chatdriver = require './rocketchat_driver'

RocketChatURL = process.env.ROCKETCHAT_URL or "localhost:3000"
RocketChatRoom = process.env.ROCKETCHAT_ROOM or "GENERAL"
RocketChatUser = process.env.ROCKETCHAT_USER or "hubot"
RocketChatPassword = process.env.ROCKETCHAT_PASSWORD or "password"
ListenOnAllPublicRooms = process.env.LISTEN_ON_ALL_PUBLIC or "false"
RespondToDirectMessage = process.env.RESPOND_TO_DM or "false"
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
						roomids = []
						subs = []
						for room in rooms
							do(room) =>
								roomids.push  @chatdriver.getRoomId(room)

						Q.all(roomids).then(
							(room_ids) =>
								for result, index in room_ids
									rooms[index] = result
									joinrooms.push @chatdriver.joinRoom(userid, RocketChatUser, result)

								@robot.logger.info "rid: ", room_ids
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
															if (newmsg.u._id isnt userid)  || (newmsg.t is 'uj')
																if (newmsg.rid in room_ids)  || (ListenOnAllPublicRooms.toLowerCase() is 'true') ||  ((RespondToDirectMessage.toLowerCase() is 'true') && (newmsg.rid.indexOf(userid) > -1))
																	curts = new Date(newmsg.ts.$date)
																	@robot.logger.info "Message receive callback id " + newmsg._id + " ts " + curts
																	@robot.logger.info "[Incoming] #{newmsg.u.username}: #{newmsg.msg}"

																	if curts > @lastts
																		@lastts = curts
																		if newmsg.t isnt 'uj'
																			user = @robot.brain.userForId newmsg.u._id, name: newmsg.u.username, room: newmsg.rid
																			text = new TextMessage(user, newmsg.msg, newmsg._id)
																			@robot.receive text
																			@robot.logger.info "Message sent to hubot brain."
																		else   # enter room message
																			if newmsg.u._id isnt userid
																				user = @robot.brain.userForId newmsg.u._id, name: newmsg.u.username, room: newmsg.rid
																				@robot.receive new EnterMessage user, null, newmsg._id

													(err) =>
														@robot.logger.error "Unable to subscribe: #{err} Reason: #{err.reason}"
												)

										(err) =>
											@robot.logger.error "Unable to Join room: #{err} Reason: #{err.reason}"
									)

							(error) =>
								@robot.logger.error "Unable to get room id: #{err} Reason: #{err.reason}"
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

	callMethod: (method, args...) =>
		@chatdriver.callMethod(method, args)

exports.use = (robot) ->
	new RocketChatBotAdapter robot
