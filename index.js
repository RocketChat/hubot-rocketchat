'use strict'

const Adapter = require.main.require('hubot/src/adapter')
const Response = require.main.require('hubot/src/response')
const { TextMessage, EnterMessage, LeaveMessage } = require.main.require('hubot/src/message')
const { driver } = require('@rocket.chat/sdk')

/** Take configs from environment settings or defaults */
const config = {
  url: process.env.ROCKETCHAT_URL || 'localhost:3000',
  room: process.env.ROCKETCHAT_ROOM || 'GENERAL',
  user: process.env.ROCKETCHAT_USER || 'hubot',
  pass: process.env.ROCKETCHAT_PASSWORD || 'password',
  listenOnAllPublic: (process.env.LISTEN_ON_ALL_PUBLIC || 'false').toLowerCase() === 'true',
  respondToDM: (process.env.RESPOND_TO_DM || 'false').toLowerCase() === 'true',
  respondToLivechat: (process.env.RESPOND_TO_LIVECHAT || 'false').toLowerCase() === 'true',
  respondToEdited: (process.env.RESPOND_TO_EDITED || 'false').toLowerCase() === 'true',
  sslEnabled: false
}

/** Extend default response with custom adapter methods */
class RocketChatResponse extends Response {
  sendDirect (...strings) {
    this.robot.adapter.sendDirect(this.envelope, ...strings)
  }
  sendPrivate (...strings) {
    this.robot.adapter.sendDirect(this.envelope, ...strings)
  }
}

/** Define new message type for handling attachments */
class AttachmentMessage extends TextMessage {
  constructor (user, attachment, text, id) {
    super(user, text, id)
    this.user = user
    this.attachment = attachment
    this.text = text
    this.id = id
  }
  toString () {
    return this.attachment
  }
}

/** Main API for Hubot on Rocket.Chat */
class RocketChatBotAdapter extends Adapter {
  run () {
    this.robot.logger.info(`[startup] Rocket.Chat adapter in use`)
    
    // Print logs with current configs
    this.startupLogs()

    // Overwrite Robot's response class with Rocket.Chat custom one
    this.robot.Response = RocketChatResponse

    // Initialise internal memory for comparing message update timestamps
    this.lastReadTime = new Date()

    // Use RocketChat Bot Driver to connect, login and setup subscriptions
    // Joins single or array of rooms by name from room setting (comma separated)
    // Reactive message subscription uses callback to process every stream update
    driver.useLog(this.robot.logger)
    driver.connect({
      host: config.url,
      useSsl: config.sslEnabled
    })
      .catch((err) => {
        this.robot.logger.error(this.robot.logger.error(`Unable to connect: ${JSON.stringify(err)}`))
        throw err
      })
      .then(() => {
        return driver.login({ username: config.user, password: config.pass })
      })
      .catch((err) => {
        this.robot.logger.error(this.robot.logger.error(`Unable to login: ${JSON.stringify(err)}`))
        throw err
      }).then((_id) => {
        this.userId = _id
        return driver.joinRooms(config.room.split(',').filter((room) => (room !== '')))
      })
      .catch((err) => {
        this.robot.logger.error(this.robot.logger.error(`Unable to join rooms: ${JSON.stringify(err)}`))
        throw err
      })
      .then((joined) => {
        return driver.subscribeToMessages()
      })
      .catch((err) => {
        this.robot.logger.error(`Unable to subscribe ${JSON.stringify(err)}`)
        throw err
      })
      .then(() => {
        driver.reactToMessages(this.process.bind(this)) // reactive callback
        this.emit('connected') // tells hubot to load scripts
      })
  }

  /** Process every incoming message in subscription */
  // @todo: break into process components for unit testing
  process (err, message, msgOpts) {
    if (err) {
      this.robot.logger.error(`Unable to receive messages ${JSON.stringify(err)}`)
      throw err
    }

    // Ignore bot's own messages
    if (message.u._id === this.userId) return

    // Ignore DMs if configured to
    const isDM = msgOpts.roomType === 'd'
    if (isDM && !config.respondToDM) return

    // Ignore Livechat if configured to
    const isLC = msgOpts.roomType === 'l'
    if (isLC && !config.respondToLivechat) return

    // Ignore messages in public rooms not joined by bot if configured to
    if (!config.listenOnAllPublic && !isDM && !msgOpts.roomParticipant) return

    // Set current time for comparison to incoming
    let currentReadTime = new Date(message.ts.$date)

    // Ignore edited messages if configured to
    // unless it's newer than current read time (hasn't been seen before)
    // @todo: test this logic, why not just return if edited and not responding
    if (config.respondToEdited && typeof message.editedAt !== 'undefined') {
      let edited = new Date(message.editedAt.$date)
      if (edited > currentReadTime) currentReadTime = edited
    }

    // Ignore messages in stream that aren't new
    if (currentReadTime <= this.lastReadTime) return

    // At this point, message has passed checks and should be processed by Hubot
    this.robot.logger.info(`Message receive callback ID ${message._id} at ${currentReadTime}`)
    this.robot.logger.info(`[Incoming] ${message.u.username}: ${(message.file !== undefined) ? message.attachments[0].title : message.msg}`)
    this.lastReadTime = currentReadTime

    // Get user from brain or store if unmet
    // @todo: insert other user fields here, like role
    // @todo: test alias field - why not u.alias
    let user = this.robot.brain.userForId(message.u._id, { name: message.u.username, alias: message.alias })

    // Set room properties depending on type and environment
    let roomLookup = (!isDM && !isLC)
      ? driver.getRoomName(message.rid)
      : Promise.resolve(message.rid)
    roomLookup
      .then((rid) => {
        this.robot.logger.debug(`Setting room ID for response as ${rid}`)
        user.room = rid
      })
      .then(() => {
        // Prepare message type for Hubot to receive...
        this.robot.logger.info('Filters passed, will receive message')

        // Room joins, receive without further detail
        if (message.t === 'uj') {
          this.robot.logger.debug('Message type EnterMessage')
          return this.robot.receive(new EnterMessage(user, null, message._id))
        }

        // Room exit, receive without further detail
        if (message.t === 'ul') {
          this.robot.logger.debug('Message type LeaveMessage')
          return this.robot.receive(new LeaveMessage(user, null, message._id))
        }

        // Direct messages prepend bot's name so Hubot can `.respond`
        const startOfText = (message.msg.indexOf('@') === 0) ? 1 : 0
        const robotIsNamed = message.msg.indexOf(this.robot.name) === startOfText || message.msg.indexOf(this.robot.alias) === startOfText
        if ((isDM || isLC) && !robotIsNamed) message.msg = `${this.robot.name} ${message.msg}`

        // Attachments, format properties for Hubot
        if (typeof (message.attachments) !== 'undefined' && message.attachments.length) {
          let attachment = message.attachments[0]
          if (attachment.image_url) {
            attachment.link = `${config.url}${attachment.image_url}`
            attachment.type = 'image'
          } else if (attachment.audio_url) {
            attachment.link = `${config.url}${attachment.audio_url}`
            attachment.type = 'audio'
          } else if (attachment.video_url) {
            attachment.link = `${config.url}${attachment.video_url}`
            attachment.type = 'video'
          }
          this.robot.logger.debug('Message type AttachmentMessage')
          return this.robot.receive(new AttachmentMessage(user, attachment, message.msg, message._id))
        }

        // Standard text messages, receive as is
        let textMessage = new TextMessage(user, message.msg, message._id)
        this.robot.logger.debug(`TextMessage: ${textMessage.toString()}`)
        return this.robot.receive(textMessage)
      })
  }

  /** Send messages to users */
  send (envelope, ...strings) {
    return driver.sendMessage(strings, envelope.room)
  }

  /** Emote message to user */
  emote (envelope, ...strings) {
    return driver.sendMessage(`_${strings}`, envelope.room)
  }

  /** Send custom message to user */
  customMessage (data) {
    return driver.customMessage(data)
  }

  /** Send DM to user */
  sendDirect (envelope, ...strings) {
    return driver.sendDirectToUser(strings, envelope.user.name)
  }

  /** Reply to a user's message (mention them if not a DM) */
  reply (envelope, ...strings) {
    if (envelope.room.indexOf(envelope.user.id) === -1) {
      strings.map((s) => `@${envelope.user.name} ${s}`)
      return this.send(envelope, ...strings)
    }
  }

  /** Get a room ID via driver */
  getRoomId (room) {
    return driver.getRoomId(room)
  }

  /** Call a server message via driver */
  callMethod (method, ...args) {
    return driver.callMethod(method, args)
  }

  /** Starting config print outs, split-out from logic for easy reading */
  startupLogs () {
    this.robot.logger.info(`[startup] Respond to the name: ${this.robot.name}`)
    this.robot.alias = (this.robot.name === config.user || this.robot.alias) ? this.robot.alias : config.user

    if (this.robot.alias) {
      this.robot.logger.info(`I will also respond to my Rocket.Chat username as an alias ${this.robot.alias}`)
    }

    if (!process.env.ROCKETCHAT_URL) {
      this.robot.logger.warning(`No services ROCKETCHAT_URL provided to Hubot, using ${config.url}`)
    }

    if (!process.env.ROCKETCHAT_ROOM) {
      this.robot.logger.warning(`No services ROCKETCHAT_ROOM provided to Hubot, using ${config.room}`)
    }

    if (!process.env.ROCKETCHAT_USER) {
      this.robot.logger.warning(`No services ROCKETCHAT_USER provided to Hubot, using ${config.user}`)
    }

    this.robot.logger.info(`[startup] Rooms specified: ${config.room}`)
  }
}

exports.use = (robot) => new RocketChatBotAdapter(robot)

