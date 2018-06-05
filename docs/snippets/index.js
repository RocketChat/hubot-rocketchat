/**
 * Code below initialises a Hubot instance, connecting to a local Rocket.Chat.
 * It is only for demonstrating the snippets in a development environment. They
 * are provided as tips for advanced use cases, not finished scripts to deploy.
 */

// Force some configs for demo
process.env.ROCKETCHAT_ROOM = 'general'
process.env.LISTEN_ON_ALL_PUBLIC = false
process.env.RESPOND_TO_EDITED = true
process.env.RESPOND_TO_DM = true
process.env.HUBOT_LOG_LEVEL = 'debug'

// Hack solution to get Hubot to load a custom local path as adapter
const { Robot } = require('hubot')
Robot.super_.prototype.loadAdapter = function () {
  this.adapter = require('../../').use(this)
  this.adapterName = 'hubot-rocketchat'
}

// Robot args --> adapterPath, adapterName, enableHttpd, botName, botAlias
const bot = new Robot(null, null, false, 'bot', 'hubot')

// Require the snippet at the path given in loading args...
// e.g. `node docs/snippets userHasRole`
const snippetArg = process.argv[2]
try {
  const snippet = require(`./${snippetArg}`)
  bot.adapter.on('connected', () => snippet.load(bot))
  bot.run()
} catch (error) {
  bot.logger.error(`Couldn't require snippet path: ./${snippetArg}`, error)
}
