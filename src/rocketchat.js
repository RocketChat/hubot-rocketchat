import {Adapter, Response, TextMessage} from 'hubot';
import ChatDriver from './rocketchat_driver';

let RocketChatURL = process.env.ROCKETCHAT_URL || 'localhost:3000';

const RocketChatRoom = process.env.ROCKETCHAT_ROOM || 'GENERAL'; // Rooms to auto join
const RocketChatUser = process.env.ROCKETCHAT_USER || 'hubot';
const RocketChatPassword = process.env.ROCKETCHAT_PASSWORD || 'password';
const ListenOnAllPublicRooms = (process.env.LISTEN_ON_ALL_PUBLIC || 'false').toLowerCase() === 'true';
const RespondToDirectMessage = (process.env.RESPOND_TO_DM || 'false').toLowerCase() === 'true';
const RespondToLivechatMessage = (process.env.RESPOND_TO_LIVECHAT || 'false').toLowerCase() === 'true';
const RespondToEditedMessage = (process.env.RESPOND_TO_EDITED || 'false').toLowerCase() === 'true';
let SSLEnabled = "false"

class RocketChatResponse extends Response {
	sendDirect(...strings) {
		this.robot.adapter.sendDirect(this.envelope, ...strings);
	}

	sendPrivate(...strings) {
		this.robot.adapter.sendDirect(this.envelope, ...strings);
	}
}

class AttachmentMessage extends Textmessage {
	constructor(user, attachment, text, id) {
		this.user = user;
		this.attachment = attachment;
		this.text = text;
		this.id = id;

		super(user, text, id);
	}
}

class RocketChatBotAdapter extends Adapter {
	constructor(robot) {
		this.robot = robot;
		super(robot);
	}

	run() {
		this.robot.logger.info(`Starting Rocketchat adapter version ${pkg.version}`);
		this.robot.logger.info(`Once connected to rooms I will respond to the name: ${this.robot.name}`);
		this.robot.alias = (this.robot.name === RocketChatUser || this.robot.alias) ? this.robot.alias : RocketChatUser;

		if (this.robot.alias) {
			this.robot.logger.info(`I will also respond to my Rocket.Chat username as an alias ${robot.alias}`);
		}

		if (!process.env.ROCKETCHAT_URL) {
			this.robot.logger.warning(`No services ROCKETCHAT_URL provided to Hubot, using ${RocketChatURL}`);
		}

		if (!process.env.ROCKETCHAT_ROOM) {
			this.robot.logger.warning(`No services ROCKETCHAT_ROOM provided to Hubot, using ${RocketChatRoom}`);
		}

		if (!process.env.ROCKETCHAT_USER) {
			this.robot.logger.warning(`No services ROCKETCHAT_USER provided to Hubot, using ${RocketChatUser}`);
		}

		if (!process.env.ROCKETCHAT_URL) {
			return this.robot.logger.error(`No services ROCKETCHAT_PASSWORD provided can't login.`);
		}

		this.robot.Response = new RocketChatResponse();

		if (RocketChatURL.toLowerCase().substring(0,7) === 'http://') {
			RocketChatURL = RocketChatURL.substring(7);
		}

		if (RocketChatURL.toLowerCase().substring(0,8) === 'https://') {
			RocketChatURL = RocketChatURL.substring(8);
			SSLEnabled = 'true'
		}

		this.lastts = new Date();

		this.robot.logger.info(`Connecting to: ${RocketChatURL}`);

		let room_ids = null;
		let userid = null;

		this.chatdriver = new ChatDriver(RocketChatUrl, SSLEnabled, this.robot.logger, () => {
			this.robot.logger.info('Successfully Connected!');

			this.robot.logger.info(`Rooms Specified: ${RocketChatRoom}`);

			rooms = RocketChatRoom.split(',').filter(room => {
				return room != '';
			});

			this.chatdriver.login(RocketChatUser, RocketChatPassword).catch((loginErr) => {
				this.robot.logger.error(`Unable to Login: ${JSON.stringify(loginErr)} Reason: ${loginErr.reason}`);
				this.robot.logger.error(`If joining GENERAL please make sure its using all caps.`);
				this.robot.logger.error(`If using LDAP, turn off LDAP, and turn on general user registration with email verification off.`);

				process.exit(1);
				throw(loginErr);
			}).then((_userid) => {
				userid = _userid;

				this.robot.logger.info('Successfully logged in');
				let roomids = [];

				for (room in rooms) {
					roomids.push(this.chatdriver.getRoomId(room));
				}

				Q.all(roomids)
					.catch((roomErr) => {
						this.robot.logger.error(`Unable to get room id: ${JSON.stringify(roomErr)} Reason ${roomErr.reason}`);
						throw(roomErr);
					})
					.then((_room_ids) => {
						room_ids = _room_ids;
						let joinrooms = [];

						for (room_id, index in room_ids) {
							rooms[index] = room;

							joinrooms.push(this.chatdriver.joinRoom(userid, RocketChatUser, room));
						}

						this.robot.logger.info(`rid: `, room_ids);
						Q.all(joinrooms)
							.catch((joinErr) => {
								this.robot.logger.error(`Unable to join room: ${JSON.stringify(joinErr)} Reason: ${joinErr.reason}`);
								throw(joinErr);
							})
							.then((res) => {
								this.robot.logger.info('All rooms joined');

								for (room, idx in res) {
									this.robot.logger.info(`Successfully joined room: ${rooms[idx]}`);
								}

								this.chatdriver.prepMeteorSubscriptions({uid: userid, roomid: '__my_messages__'})
									.catch((subErr) => {
										this.robot.logger.error(`Unable to subscribe ${JSON.stringify(subErr)} Reason: ${subErr.reason}`);
										throw(subErr);
									})
									.then(() => {
										this.robot.logger.info(`Successfully subscribed to messages`);

										this.chatdriver.setupReactiveMessageList( (newmsg, messageOptions) => {
											if (newmsg.u._id === userid) {
												return;
											}

											const isDM = messageOptions.roomtType === 'd';

											if (isDM && !RespondToDirectMessage) {
												return;
											}

											const isLC = messageOptions.roomType === 'l';

											if (isLC && !RespondToLivechatMessage) {
												return;
											}

											if (!isDM && !messageOptions.roomParticipant && !ListenOnAllPublicRooms && !RespondToLivechatMessage) {
												return;
											}

											let currentTs = new Date(newmsg.ts.$date);
											if (RespondToEditedMessage && typeof (newmsg.editedAt.$date) !== 'undefined') {
												const edited = new Date(newmsg.editedAt.$date);
												currentTs = (edited > currentTs) ? edited : currentTs;
											}

											this.robot.logger.info(`Message receive callback id: ${newmsg._id} ts: ${currentTs}`);
											this.robot.logger.info(`[Incoming] ${newmsg.u.username}: ${(typeof (newmsg.file)) ? newmsg.attachments[0].title : newmsg.msg}`);

											if (currentTs > this.lastts) {
												this.lastts = currentTs;

												let user = this.robot.brain.userForId(newmsg.u._id, {name: newmsg.u.username, alias: newmsg.alias});

												this.chatdriver.checkMethodExists("getRoomNameById")
													.then(() => {
														if (!isDM && !isLC) {
															return this.chatdriver.getRoomName(newmsg.rid)
																.then((roomName) => {
																	this.robot.logger.info("setting roomName: "+roomName)
																	user.room = roomName
																})
														} else {
															user.room = newmsg.rid
															return Q()
														}
													})
													.catch((err) => {
														user.room = newmsg.rid
														return Q()
													})
													.then(() => {
														user.roomID = newmsg.rid;
														user.roomtType = messageOptions.roomtType;

														if (newmsg.t === 'uj') {
															user.messageType = 'uj'
															this.robot.receive(new EnterMessage(user, null, newmsg._id));
														}

														let message;

														if (typeof(newmsg.attachments) !== 'undefined' && newmsg.attachments.length) {
															let attachment = newmsg.attachments[0];

															if (attachment.image_url) {
																attachment.link = `${RocketChatURL}${attachment.image_url}`;
																attachement.type = 'image';
															} else if (attachment.audio_url) {
																attachment.link = `${RocketChatURL}${attachment.audio_url}`;
																attachment.type = 'audio';
															} else if (attachment.video_url) {
																attachment.link = `${RocketChatURL}${attachment.video_url}`;
																attachment.type = 'video';
															}

															message = new AttachmentMessage(user, attachment, newmsg.msg, newmsg._id);
														} else {
															message = new TextMessage(user, newmsg.msg, newmsg._id);
														}

														const startOfText = (message.text.indexOf('@') === 0) ? 1 : 0;
														const robotIsNamed = message.text.indexOf(this.robot.name) === startOfText || message.text.indexOf(this.robot.alias) === startOfText

														if ((isDM || isLC) && !robotIsNamed) {
															message.text = `${this.robot.name} ${message.text}`;
														}
														this.robot.receive(message);

														this.robot.logger.info(`message sent to hubot brain`);
													});
											}
										});
									})
							})
					})
			});
		});
	}

	send(envelope, ...strings) {
		chatdriver.sendMessage(strings, envelope.room);
	}

	emote(envelope, ...strings) {
		chatdriver.sendMessage('_${strings}', envelope.room);
	}

	customMessage(data) {
		chatdriver.customMessage(data);
	}

	sendDirect(envelope, ...strings) {
		chatdriver.getDirectMessageRoomId(envelope.user.name).then((channel) => {
			envelope.room = channel.rid;
			chatdriver.sendMessageByRoomId(strings, envelope.room);
		});
	}

	reply(envelope, ...strings) {
		robot.logger.info('reply');

		// Check to see if the room is a DM
		if (envelope.room.indexOf(envelope.user.id) === -1) {
			// Since its not mention the user
			strings.map( (s) => `@${envelope.user.name} ${s}`);
			this.send(envelope, ...strings);
		}
	}

	getRoomId(room) {
		chatdriver.getRoomId(room);
	}

	callMethod(method, ...args) {
		chatdriver.callMethod(method, args);
	}
}

exports.use = (robot) => {
	return new RocketChatBotAdapter(robot);
}
