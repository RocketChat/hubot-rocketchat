// Description:
//   Get version info for debugging in Rocket.Chat
//
// Dependencies:
//   hubot-rocketchat
//
// Configuration:
//   None
//
// Commands:
//   hubot rc version - < Tells you the Hubot, Driver and Rocket.Chat versions >
//
// Notes:
//   Version 1.0
//
// Author:
//   Rocket.Chat
module.exports = (robot) => {
  robot.respond(/\brc(-|\s)version\b/i, function(res) {
    const hubotPackage = require.main.require('hubot/package.json')
    const adapterPackage = require.main.require('hubot-rocketchat/package.json')
    const sdkPackage = require.main.require('@rocket.chat/sdk/package.json')
    robot.adapter.callMethod('getServerInfo').then((result) => {
      res.send(
        `You're on Rocket.Chat ${result.version}, using Hubot ${hubotPackage.version}.`,
        `Adapter version ${adapterPackage.version}, using version ${sdkPackage.version} of the SDK.`
      )
    })
  })
}
