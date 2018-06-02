'use strict'

const Adapter = require.main.require('hubot/src/adapter')
const Response = require.main.require('hubot/src/response')
const { TextMessage, EnterMessage, LeaveMessage } = require.main.require('hubot/src/message')
const { driver, api, methodCache, settings } = require('@rocket.chat/sdk')

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

    // Make SDK modules available to scripts, via `adapter.`
    this.driver = driver
    this.methodCache = methodCache
    this.api = api
    this.settings = settings

    // Print logs with current configs
    this.robot.logger.info(`[startup] Respond to name: ${this.robot.name}`)
    this.robot.alias = (this.robot.name === settings.username || this.robot.alias)
      ? this.robot.alias
      : settings.username
    if (this.robot.alias) {
      this.robot.logger.info(`[startup] Respond to alias: ${this.robot.alias}`)
    }

    // Overwrite Robot's response class with Rocket.Chat custom one
    this.robot.Response = RocketChatResponse

    // Use RocketChat Bot Driver to connect, login and setup subscriptions
    // Joins single or array of rooms by name from room setting (comma separated)
    // Reactive message subscription uses callback to process every stream update
    driver.useLog(this.robot.logger)
    driver.connect()
      .catch((err) => {
        this.robot.logger.error(this.robot.logger.error(`Unable to connect: ${JSON.stringify(err)}`))
        throw err
      })
      .then(() => {
        return driver.login()
      })
      .catch((err) => {
        this.robot.logger.error(this.robot.logger.error(`Unable to login: ${JSON.stringify(err)}`))
        throw err
      })
      .then(() => {
        return driver.subscribeToMessages()
      })
      .catch((err) => {
        this.robot.logger.error(`Unable to subscribe ${JSON.stringify(err)}`)
        throw err
      })
      .then(() => {
        driver.respondToMessages(this.process.bind(this)) // reactive callback
        this.emit('connected') // tells hubot to load scripts
      })
  }

  /** Process every incoming message in subscription */
  process (err, message, meta) {
    if (err) throw err
    // Prepare message type for Hubot to receive...
    this.robot.logger.info('Filters passed, will receive message')

    // Collect required attributes from message meta
    const isDM = (meta.roomType === 'd')
    const isLC = (meta.roomType === 'l')
    const user = this.robot.brain.userForId(message.u._id, {
      name: message.u.username,
      alias: message.alias
    })
    user.roomID = message.rid
    user.roomType = meta.roomType
    user.room = meta.roomName || message.rid

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
    if (Array.isArray(message.attachments) && message.attachments.length) {
      let attachment = message.attachments[0]
      if (attachment.image_url) {
        attachment.link = `${settings.host}${attachment.image_url}`
        attachment.type = 'image'
      } else if (attachment.audio_url) {
        attachment.link = `${settings.host}${attachment.audio_url}`
        attachment.type = 'audio'
      } else if (attachment.video_url) {
        attachment.link = `${settings.host}${attachment.video_url}`
        attachment.type = 'video'
      }
      this.robot.logger.debug('Message type AttachmentMessage')
      return this.robot.receive(new AttachmentMessage(user, attachment, message.msg, message._id))
    }

    // Standard text messages, receive as is
    let textMessage = new TextMessage(user, message.msg, message._id)
    this.robot.logger.debug(`TextMessage: ${textMessage.toString()}`)
    return this.robot.receive(textMessage)
  }

  /** Send messages to user addressed in envelope */
  send (envelope, ...strings) {
    return strings.map((text) => {
      if (envelope.user && envelope.user.roomID) driver.sendToRoomId(text, envelope.user.roomID)
      else driver.sendToRoom(text, envelope.room)
    })
  }

  /**
   * Emote message to user
   * @todo Improve this legacy method
   */
  emote (envelope, ...strings) {
    return strings.map((text) => this.send(envelope, `_${text}_`))
  }

  /** Send custom message to user */
  customMessage (data) {
    return driver.sendMessage(data)
  }

  /** Send DM to user */
  sendDirect (envelope, ...strings) {
    return strings.map((text) => driver.sendDirectToUser(text, envelope.user.name))
  }

  /** Reply to a user's message (mention them if not a DM) */
  reply (envelope, ...strings) {
    if (envelope.room.indexOf(envelope.user.id) === -1) {
      strings = strings.map((s) => `@${envelope.user.name} ${s}`)
    }
    return this.send(envelope, ...strings)
  }

  /** Get a room ID via driver */
  getRoomId (room) {
    return driver.getRoomId(room)
  }

  /** Call a server message via driver */
  callMethod (method, ...args) {
    return driver.callMethod(method, args)
  }
}

exports.use = (robot) => new RocketChatBotAdapter(robot)
