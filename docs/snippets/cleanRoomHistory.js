/**
 * Use API to clear the room history (useful in testing, dangerous otherwise).
 * Bot requires `clean-channel-history` permission.
 * Test with `node docs/snippets cleanRoomHistory` from project root.
 * @param {Robot} robot        Hubot instance
 * @param {User} user          Hubot user object containing name and room
 * @param {string} oldest      ISO date string to clean all messages since then
 * @return {boolean|undefined} If room was cleaned
 */
async function cleanRoomHistory (robot, user, oldest) {
  try {
    const latest = new Date().toISOString()
    const roomId = user.roomID
    robot.logger.info(`[cleanRoomHistory] ${user.name} cleaning room ${user.room} from ${oldest} to ${latest}`)
    await robot.adapter.api.post('rooms.cleanHistory', { roomId, latest, oldest })
    return true
  } catch (err) {
    robot.logger.error(`[cleanRoomHistory] failed, ensure bot has \`clean-channel-history\` permission`, err)
  }
}

/**
 * Add command for bot to clear the room history (requires client reload).
 * e.g. "bot clr" or "@bot clear room" or "bot clr from June 3, 2018 17:30".
 * @param {Robot} robot The Hubot instance
 */
function load (robot) {
  robot.respond(/\b(clean room|clr)( from (.*))?(\.|!|)?$/i, async (res) => {
    try {
      const from = res.match[3] || 'May 19, 2015 04:36:09' // clear all if not given date
      const oldest = new Date(from).toISOString()
      const cleaned = await cleanRoomHistory(robot, res.message.user, oldest).catch()
      if (typeof cleaned === 'undefined') {
        res.reply(`Sorry, I'm afraid I can't do that.`)
      }
    } catch (err) {
      res.reply(`That wasn't a valid date`)
    }
  })
}

module.exports = {
  cleanRoomHistory,
  load
}
