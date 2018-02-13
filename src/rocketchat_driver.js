const Asteroid = require('asteroid');
const Q = require('q');
const LRU = require('lru-cache');

const _msgsubtopic = 'stream-room-messages';
const _msgsublimit = 10;
const _messageCollection = 'stream-room-messages';
const _methodExists = {};
const _roomCacheSize = parseInt(process.env.ROOM_ID_CACHE_SIZE) || 10;
const _directMessageRoomCacheSize = parseInt(process.env.DM_ROOM_ID_CACHE_SIZE) || 100;
const _cacheMaxAge = parseInt(process.env.ROOM_ID_CACHE_MAX_AGE) || 300;

const _roomIdCache = LRU({
	max: _roomCacheSize,
	maxAge: 1000 * _cacheMaxAge
});

const _directMessageRoomIdCache = LRU({
	max: _directMessageRoomCacheSize,
	maxAge: 1000 * _cacheMaxAge
});

const _roomNameCache = LRU({
	max: _roomCacheSize,
	maxAge: 1000 * _cacheMaxAge
});

class RocketChatDriver {
	constructor(url, ssl, logger, cb) {
		this.logger = logger;
		this.sslenable = false;

		if (ssl === 'true') {
			this.sslenable = true;
		}

		this.asteroid = new Asteroid(url, this.sslenable);
		this.asteroid.on('connected', () => cb());
		this.asteroid.on('reconnected', () => cb());
	}

	getRoomId(room) {
		this.tryCache(_roomIdCache, 'getRoomIdByNameOrId', room, 'Room ID');
	}

	getRoomName(room) {
		this.tryCache(_roomNameCache, 'getRoomNameById', room, 'Room Name');
	}

	getDirectMessageRoomId(username) {
		this.tryCache(_directMessageRoomIdCache, 'createDirectMessage', username, 'DM Room ID');
	}

	checkMethodExists(method) {
		if (_methodExists[method] == null) {
			this.logger.info("Checking to see if method: " + method + " exists");
			r = this.asteroid.call(method, "")
			return r.result.then((res) => {
				_methodExists[method] = true;
				return Q();
			}).catch((err) => {
				if (err.error === 404) {
					_methodExists[method] = false;
					this.logger.info("Method: " + method + " does not exist");
					return Q.reject("Method: " + method + " does not exist");
				} else {
					_methodExists[method] = true;
					return Q();
				}
			});
		} else {
			if (_methodExists[method]) {
				return Q();
			} else {
				return Q.reject();
			}
		}
	};

	tryCache(cacheArray, method, key, name) {
		if (name === null) {
			name = method;
		}

		let cached = cacheArray.get(key);
		if (cached) {
			this.logger.debug(`Found cached ${name} for ${key}: ${cached}`);
			return Q(cached);
		} else {
			this.logger.debug(`Looking up ${name} for: ${key}`);

			this.asteroid.call(method, key).result.then((res) => {
				cacheArray.set(key, res);
				return Q(res);
			})
		}
	}

	joinRoom(userid, uname, roomid, cb) {
		this.logger.info(`Joining Room: ${roomid}`);

		const r = this.asteroid.call('joinRoom', roomid);

		return r.updated;
	}

	prepareMessage(content, roomid) {
		this.logger.info(`Preparing message from ${typeof content}`);
		if (typeof content === 'string') {
			message = { msg: content, rid: roomid };
		} else {
			message = content;
			message.rid = roomid;
		}

		return message;
	}

	sendMessage(message, room) {
		this.logger.info(`Sending Message To Room ${room}`);

		const r = this.getRoomId(room);
		r.then((roomId) => {
			this.sendMessageByRoomId(message, roomid);
		});
	}

	sendMessageByRoomId(content, roomid) {
		const message = this.prepareMessage(content, roomid);

		Q(this.asteroid.call('sendMessage', message)).then((result) => {
			this.logger.debug('[sendMessage] Success:', result);
		}).catch((err) => {
			this.logger.error('[sendMessage] Error:', error);
		})
	}

	customMessage(message) {
		this.logger.info(`Sending custom message to room: ${message.channel}`);

		this.asteroid.call('sendMessage', {
			msg: message.msg || '',
			rid: message.channel,
			attachments: message.attachments,
			bot: true,
			groupable: false,
			alias: message.alias,
			avatar: message.avatar,
			emoji: message.emoji,
		});
	}

	login(username, password) {
		this.logger.info('Logging in')

		if (process.env.ROCKETCHAT_AUTH === 'ldap') {
			return this.asteroid.login({
				ldap: true,
				username: username,
				ldapPass: password,
				ldapOptions: {}
			});
		} else {
			return this.asteroid.loginWithPassword(username, password);
		}
	}

	prepMeteorSubscriptions(data) {
		this.logger.info('Preparing Meteor Subscriptions...');
		const msgsub = this.asteroid.subscribe(_msgsubtopic, data.roomid, true);
		this.logger.info(`subscribing to room: ${data.roomid}`);
		return msgsub.ready;
	}

	setupReactiveMessageList(receiveMessageCallback) {
		this.logger.info(`Setting up reactive message list...`);
		this.messages = this.asteroid.getCollection(_messageCollection);

		rQ = this.messages.reactiveQuery({});
		rQ.on('change', (id) => {
			const changedMsgQuery = this.messages.reactiveQuery({ '_id': id });
			if (changedMsgQuery.result && changedMsgQuery.result.length > 0) {
				changedMsg = changedMsgQuery.result[0];

				if (changedMsg.args !== null) {
					this.logger.info(`Message received with ID: ${id}`);
					receiveMessageCallback(changedMsg.args[0], changedMsg.args[1]);
				}
			}
		});
	}

	callMethod(name, args) {
		this.logger.info(`Calling: ${name}, ${args.join(', ')}`);

		const r = this.asteroid.apply(name, args);
		return r.result;
	}
}

module.exports = RocketChatDriver
