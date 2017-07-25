# Adding some documentation
# Adding something else

Asteroid = require 'asteroid'
Q = require 'q'
LRU = require('lru-cache')

# TODO:   need to grab these values from process.env[]

_msgsubtopic = 'stream-room-messages' # 'messages'
_msgsublimit = 10 # this is not actually used right now
_messageCollection = 'stream-room-messages'

_methodExists = {}

# room id cache
_roomCacheSize = parseInt(process.env.ROOM_ID_CACHE_SIZE) || 10
_directMessageRoomCacheSize = parseInt(process.env.DM_ROOM_ID_CACHE_SIZE) || 100
_cacheMaxAge = parseInt(process.env.ROOM_ID_CACHE_MAX_AGE) || 300
_roomIdCache = LRU(max: _roomCacheSize, maxAge: 1000 * _cacheMaxAge)
_directMessageRoomIdCache = LRU(max: _directMessageRoomCacheSize, maxAge: 1000 * _cacheMaxAge)
_roomNameCache = LRU(max: _roomCacheSize, maxAge: 1000 * _cacheMaxAge)

# driver specific to Rocketchat hubot integration
# plugs into generic rocketchatbotadapter

class RocketChatDriver
	constructor: (url, ssl, @logger, cb) ->
		if ssl is 'true'
			sslenable = true
		else
			sslenable = false

		@asteroid = new Asteroid(url, sslenable)

		@asteroid.on 'connected', ->
			cb()

		@asteroid.on 'reconnected', ->
			cb()

	getRoomId: (room) =>
		@tryCache _roomIdCache, 'getRoomIdByNameOrId', room, 'Room ID'

	getRoomName: (room) =>
		@tryCache _roomNameCache, 'getRoomNameById', room, 'Room Name'

	getDirectMessageRoomId: (username) =>
		@tryCache _directMessageRoomIdCache, 'createDirectMessage', username, 'DM Room ID'

	checkMethodExists: (method) =>
		if !_methodExists[method]?
			@logger.info "Checking to see if method: #{method} exists"
			r = @asteroid.call(method, "")
			r.result.then((res) =>
				_methodExists[method] = true
				return Q()
			).catch((err) =>
				if err.error == 404
					_methodExists[method] = false
					@logger.info "Method: #{method} does not exist"
					return Q.reject("Method: #{method} does not exist")
				else
					_methodExists[method] = true
					return Q()
			)
		else
			if _methodExists[method]
				return Q()
			else
				return Q.reject()

	tryCache: (cacheArray, method, key, name) =>
		name ?= method
		cached = cacheArray.get key
		if cached
			@logger.debug "Found cached #{name} for #{key}: #{cached}"
			return Q(cached)
		else
			@logger.info "Looking up #{name} for: #{key}"
			r = @asteroid.call method, key
			return r.result.then((res) =>
				cacheArray.set key, res
				return Q(res)
			)

	joinRoom: (userid, uname, roomid, cb) =>
		@logger.info "Joining Room: #{roomid}"

		r = @asteroid.call 'joinRoom', roomid

		return r.updated

	prepareMessage: (content, roomid) =>
		@logger.debug "Preparing message from #{ typeof content }"
		if typeof content is 'string'
			message = {msg: content, rid: roomid}
		else
			message = content
			message.rid = roomid
		return message

	sendMessage: (message, room) =>
		@logger.info "Sending Message To Room: #{room}"
		r = @getRoomId room
		r.then (roomid) =>
			@sendMessageByRoomId message, roomid

	sendMessageByRoomId: (content, roomid) =>
		message = @prepareMessage content, roomid
		Q(@asteroid.call('sendMessage', message))
		.then (result)->
			@logger.debug('[sendMessage] Success:', result)
		.catch (error) ->
			@logger.error('[sendMessage] Error:', error)

	customMessage: (message) =>
		@logger.info "Sending Custom Message To Room: #{message.channel}"

		@asteroid.call('sendMessage', {
			msg: message.msg || '',
			rid: message.channel,
			attachments: message.attachments,
			bot: true,
			groupable: false,
			alias: message.alias,
			avatar: message.avatar,
			emoji: message.emoji,
		})

	login: (username, password) =>
		@logger.info "Logging In"
		# promise returned
		if process.env.ROCKETCHAT_AUTH is 'ldap'
			return @asteroid.login
				ldap: true
				username: username
				ldapPass: password
				ldapOptions: {}
		else
			return @asteroid.loginWithPassword username, password

	prepMeteorSubscriptions: (data) =>
		# use data to cater for param differences - until we learn more
		#  data.uid
		#  data.roomid
		# return promise
		@logger.info "Preparing Meteor Subscriptions.."
		msgsub = @asteroid.subscribe _msgsubtopic, data.roomid, true
		@logger.info "Subscribing to Room: #{data.roomid}"
		return msgsub.ready

	setupReactiveMessageList: (receiveMessageCallback) =>
		@logger.info "Setting up reactive message list..."
		@messages = @asteroid.getCollection _messageCollection

		rQ = @messages.reactiveQuery {}
		rQ.on "change", (id) =>
			# awkward syntax due to asteroid limitations
			# - it ain't no minimongo cursor
			# @logger.info "Change received on ID " + id
			changedMsgQuery = @messages.reactiveQuery {"_id": id}
			if changedMsgQuery.result && changedMsgQuery.result.length > 0
				# console.log('result:', JSON.stringify(changedMsgQuery.result, null, 2))
				changedMsg = changedMsgQuery.result[0]
				# console.log('changed:', JSON.stringify(changedMsg, null, 2));
				if changedMsg.args?
					@logger.info "Message received with ID " + id
					receiveMessageCallback changedMsg.args[0], changedMsg.args[1]

	callMethod: (name, args = []) =>
		@logger.info "Calling: #{name}, #{args.join(', ')}"
		r = @asteroid.apply name, args
		return r.result

module.exports = RocketChatDriver
