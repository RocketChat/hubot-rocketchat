# Hubot adapter for Rocket.Chat
# For configuration and deployment details, see https://github.com/RocketChat/hubot-rocketchat/blob/master/README.md
#
# The RocketChatBotAdapter class implements 'standard' hubot Adapter interface methods.
#
# Most of the Rocket.Chat specific code, tied to Rocket.Chat's real-time messaging APIs, are isolated in
# a seperate RocketChatDriver class.

try
		{Robot,Adapter,TextMessage, EnterMessage, User, Response} = require 'hubot'
catch
		prequire = require('parent-require')
		{Robot,Adapter,TextMessage, EnterMessage, User, Response} = prequire 'hubot'
pkg = require '../package.json'
Q = require 'q'
Chatdriver = require './rocketchat_driver'

RocketChatURL = process.env.ROCKETCHAT_URL or "localhost:3000"
RocketChatRoom = process.env.ROCKETCHAT_ROOM or "GENERAL" # Rooms to auto join
RocketChatUser = process.env.ROCKETCHAT_USER or "hubot"
RocketChatPassword = process.env.ROCKETCHAT_PASSWORD or "password"
ListenOnAllPublicRooms = (process.env.LISTEN_ON_ALL_PUBLIC or "false").toLowerCase() is 'true'
RespondToDirectMessage = (process.env.RESPOND_TO_DM or "false").toLowerCase() is 'true'
RespondToLivechatMessage = (process.env.RESPOND_TO_LIVECHAT or "false").toLowerCase() is "true"
RespondToEditedMessage = (process.env.RESPOND_TO_EDITED or "false").toLowerCase() is 'true'
SSLEnabled = "false"

if ListenOnAllPublicRooms
	RocketChatRoom = ''

# Custom Response class that adds a sendPrivate and sendDirect method
class RocketChatResponse extends Response
	sendDirect: (strings...) ->
		@robot.adapter.sendDirect @envelope, strings...
	sendPrivate: (strings...) ->
		@robot.adapter.sendDirect @envelope, strings...

class AttachmentMessage extends TextMessage
	constructor: (@user, @attachment, @text, @id) ->
		super @user, @text, @id

class RocketChatBotAdapter extends Adapter

	run: =>
		@robot.logger.info "Starting Rocketchat adapter version #{pkg.version}..."

		@robot.logger.info "Once connected to rooms I will respond to the name: #{@robot.name}"
		@robot.alias = RocketChatUser unless @robot.name is RocketChatUser || @robot.alias
		@robot.logger.info "I will also respond to my Rocket.Chat username as an alias: #{ @robot.alias }" unless @robot.alias is false

		@robot.logger.warning "No services ROCKETCHAT_URL provided to Hubot, using #{RocketChatURL}" unless process.env.ROCKETCHAT_URL
		@robot.logger.warning "No services ROCKETCHAT_ROOM provided to Hubot, using #{RocketChatRoom}" unless process.env.ROCKETCHAT_ROOM
		@robot.logger.warning "No services ROCKETCHAT_USER provided to Hubot, using #{RocketChatUser}" unless process.env.ROCKETCHAT_USER
		return @robot.logger.error "No services ROCKETCHAT_PASSWORD provided to Hubot" unless RocketChatPassword

		@robot.Response = RocketChatResponse

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

			rooms = RocketChatRoom.split(',').filter (room) ->
				room != ''
			# @robot.logger.info JSON.stringify(rooms)

			# Log in
			@chatdriver.login(RocketChatUser, RocketChatPassword)
			.catch((loginErr) => # Only catch in the main chain aside from final exit
				@robot.logger.error "Unable to Login: #{JSON.stringify(loginErr)} Reason: #{loginErr.reason}"
				@robot.logger.error "If joining GENERAL please make sure its using all caps."
				@robot.logger.error "If using LDAP, turn off LDAP, and turn on general user registration with email
					verification off."
				process.exit 1 #hack to make hubot die on login error to fix #203
				throw loginErr #rethrow to exit the chain
			)
			# Get room IDS
			.then((_userid) =>
				userid = _userid
				@robot.logger.info "Successfully Logged In"
				roomids = []
				for room in rooms
					do(room) =>
						roomids.push @chatdriver.getRoomId(room)

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
				for result, idx in res
					@robot.logger.info "Successfully joined room: #{rooms[idx]}"

				return @chatdriver.prepMeteorSubscriptions({uid: userid, roomid: '__my_messages__'})
				.catch((subErr) =>
					@robot.logger.error "Unable to subscribe: #{JSON.stringify(subErr)} Reason: #{subErr.reason}"
					throw subErr
				)
			)
			# Setup msg callbacks
			.then(() =>
				@robot.logger.info "Successfully subscribed to messages"

				@chatdriver.setupReactiveMessageList (newmsg, messageOptions) =>
					if newmsg.u._id is userid
						return

					isDM = messageOptions.roomType is 'd'

					if isDM and not RespondToDirectMessage
						return

					isLC = messageOptions.roomType is 'l'

					if isLC and not RespondToLivechatMessage
						return

					if not isDM and not messageOptions.roomParticipant and not ListenOnAllPublicRooms and not RespondToLivechatMessage
						return

					curts = new Date(newmsg.ts.$date)
					if RespondToEditedMessage and newmsg.editedAt?.$date?
						edited = new Date(newmsg.editedAt.$date)
						curts = if edited > curts then edited else curts
					@robot.logger.info "Message receive callback id " + newmsg._id + " ts " + curts
					@robot.logger.info "[Incoming] #{newmsg.u.username}: #{if newmsg.file? then newmsg.attachments?[0]?.title else newmsg.msg}"

					if curts > @lastts
						@lastts = curts

						user = @robot.brain.userForId newmsg.u._id, name: newmsg.u.username, alias: newmsg.alias

						@chatdriver.checkMethodExists("getRoomNameById").then(() =>
							if not isDM and not isLC
								return @chatdriver.getRoomName(newmsg.rid).then((roomName) =>
									@robot.logger.info("setting roomName: #{roomName}")
									user.room = roomName
								)
							else
								user.room = newmsg.rid
								return Q()
						).catch((err) =>
							user.room = newmsg.rid
							return Q()
						).then(() =>
							user.roomID = newmsg.rid

							if newmsg.t is 'uj'
								@robot.receive new EnterMessage user, null, newmsg._id
							else
							# check for the presence of attachments in the message
							if newmsg.attachments? and newmsg.attachments.length
								attachment = newmsg.attachments[0]

								if attachment.image_url?
									attachment.link = "#{RocketChatURL}#{attachment.image_url}"
									attachment.type = 'image'
								else if attachment.audio_url?
									attachment.link = "#{RocketChatURL}#{attachment.audio_url}"
									attachment.type = 'audio'
								else if attachment.video_url?
									attachment.link = "#{RocketChatURL}#{attachment.video_url}"
									attachment.type = 'video'

								message = new AttachmentMessage user, attachment, newmsg.msg, newmsg._id
							else
								message = new TextMessage user, newmsg.msg, newmsg._id

							startOfText = if message.text.indexOf('@') == 0 then 1 else 0
							robotIsNamed = message.text.indexOf(@robot.name) == startOfText || message.text.indexOf(@robot.alias) == startOfText
							if (isDM or isLC) and not robotIsNamed
								message.text = "#{ @robot.name } #{ message.text }"
							@robot.receive message
							@robot.logger.info "Message sent to hubot brain."
						)
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

	emote: (envelope, strings...) =>
		@chatdriver.sendMessage("_#{str}_", envelope.room) for str in strings

	customMessage: (data) =>
		@chatdriver.customMessage(data)

	sendDirect: (envelope, strings...) =>
		channel = @chatdriver.getDirectMessageRoomId(envelope.user.name)
		Q(channel)
		.then((chan) =>
			envelope.room = chan.rid
			@chatdriver.sendMessageByRoomId(str, envelope.room) for str in strings
		)
		.catch((err) =>
			@robot.logger.error "Unable to get DirectMessage Room ID: #{JSON.stringify(err)} Reason: #{err.reason}"
		)

	reply: (envelope, strings...) =>
		@robot.logger.info "reply"
		isDM = envelope.room.indexOf(envelope.user.id) > -1
		unless isDM
			strings = strings.map (s) -> "@#{envelope.user.name} #{s}"
		@send envelope, strings...

	getRoomId: (room) =>
		@chatdriver.getRoomId(room)

	callMethod: (method, args...) =>
		@chatdriver.callMethod(method, args)

exports.use = (robot) ->
	new RocketChatBotAdapter robot
