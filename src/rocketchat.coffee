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
SSLEnabled = "false"
class RocketChatBotAdapter extends Adapter

	run: =>
		@robot.logger.info "Starting Rocketchat adapter..."

		@robot.logger.info "Once connected to rooms I will respond to the name: #{@robot.name}"

		@robot.logger.warning "No services ROCKETCHAT_URL provided to Hubot, using #{RocketChatURL}" unless process.env.ROCKETCHAT_URL
		@robot.logger.warning "No services ROCKETCHAT_ROOM provided to Hubot, using #{RocketChatRoom}" unless process.env.ROCKETCHAT_ROOM
		@robot.logger.warning "No services ROCKETCHAT_USER provided to Hubot, using #{RocketChatUser}" unless process.env.ROCKETCHAT_USER
		return @robot.logger.error "No services ROCKETCHAT_PASSWORD provided to Hubot" unless RocketChatPassword


		if RocketChatURL.toLowerCase().substring(0,7) == "http://"
			RocketChatURL = RocketChatURL.substring(7)

		if RocketChatURL.toLowerCase().substring(0,8) == "https://"
			RocketChatURL = RocketChatURL.substring(8)
			SSLEnabled = "true"


		@lastts = new Date()

		@robot.logger.info "Connecting To: #{RocketChatURL}"

		room_ids = null
		userid = null

		@chatdriver = new Chatdriver RocketChatURL, SSLEnabled, @robot.logger, =>
			@robot.logger.info "Successfully connected!"
			@robot.logger.info RocketChatRoom

			rooms = RocketChatRoom.split(',')
			# @robot.logger.info JSON.stringify(rooms)

			# Log in
			@chatdriver.login(RocketChatUser, RocketChatPassword)
			.catch((loginErr) => # Only catch in the main chain aside from final exit
				@robot.logger.error "Unable to Login: #{JSON.stringify(loginErr)} Reason: #{loginErr.reason}"
				@robot.logger.error "If joining GENERAL please make sure its using all caps."
				@robot.logger.error "If using LDAP, turn off LDAP, and turn on general user registration with email
					verification off."
				throw loginErr #rethrow to exit the chain
			)
			# Get room IDS
			.then((_userid) =>
				userid = _userid
				@robot.logger.info "Successfully Logged In"
				roomids = []
				for room in rooms
					do(room) =>
						roomids.push	@chatdriver.getRoomId(room)

				return Q.all(roomids)
				.catch((roomErr) =>
					@robot.logger.error "Unable to get room id: #{JSON.stringify(roomErr)} Reason: #{roomErr.reason}"
					throw roomErr
				)
			)
			# Join all specified rooms
			.then((_room_ids) =>
				room_ids = _room_ids
				joinrooms = []
				for result, index in room_ids
					rooms[index] = result
					joinrooms.push @chatdriver.joinRoom(userid, RocketChatUser, result)

				@robot.logger.info "rid: ", room_ids
				return Q.all(joinrooms)
				.catch((joinErr) =>
					@robot.logger.error "Unable to Join room: #{JSON.stringify(joinErr)} Reason: #{joinErr.reason}"
					throw joinErr
				)
			)
			# Subscribe to msgs in all rooms
			.then((res) =>
				@robot.logger.info "All rooms joined."
				subs = []
				for result, idx in res
					@robot.logger.info "Successfully joined room: #{rooms[idx]}"
					subs.push @chatdriver.prepMeteorSubscriptions({uid: userid, roomid: rooms[idx]})

				return Q.all(subs)
				.catch((subErr) =>
					@robot.logger.error "Unable to subscribe: #{JSON.stringify(subErr)} Reason: #{subErr.reason}"
					throw subErr
				)
			)
			# Setup msg callbacks
			.then((results) =>
				@robot.logger.info "All subscriptions ready."
				for result, idx in results
					@robot.logger.info "Successfully subscribed to room: #{rooms[idx]}"

				@chatdriver.setupReactiveMessageList (newmsg) =>
					if (newmsg.u._id isnt userid) || (newmsg.t is 'uj')
						if (newmsg.rid in room_ids)	|| (ListenOnAllPublicRooms.toLowerCase() is 'true') ||	((RespondToDirectMessage.toLowerCase() is 'true') && (newmsg.rid.indexOf(userid) > -1))
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
								else	 # enter room message
									if newmsg.u._id isnt userid
										user = @robot.brain.userForId newmsg.u._id, name: newmsg.u.username, room: newmsg.rid
										@robot.receive new EnterMessage user, null, newmsg._id
			)
			.then(() =>
				@emit 'connected'
			)
			# Final exit, all throws skip to here
			.catch((err) =>
				@robot.logger.error JSON.stringify(err)
				@robot.logger.error "Unable to complete setup. See https://github.com/RocketChat/hubot-rocketchat for more info."
			)

	send: (envelope, strings...) =>
		@chatdriver.sendMessage(str, envelope.room) for str in strings
			
	customMessage: (data) =>
		@chatdriver.customMessage(data)

	reply: (envelope, strings...) =>
		@robot.logger.info "reply"
		strings = strings.map (s) -> "@#{envelope.user.name} #{s}"
		@send envelope, strings...

	callMethod: (method, args...) =>
		@chatdriver.callMethod(method, args)

exports.use = (robot) ->
	new RocketChatBotAdapter robot
