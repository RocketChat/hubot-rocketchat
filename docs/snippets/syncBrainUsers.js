/**
 * Use API user helper to sync RC users with Hubot brain.
 * Test with `node docs/snippets syncBrainUsers` from project root.
 * @param {Robot} robot        The Hubot instance
 * @returns {string|undefined} List of names added
 */
async function syncBrainUsers (robot) {
  try {
    robot.logger.info(`[syncBrainUsers] adding all users to Hubot brain`)
    const allUsers = await robot.adapter.api.users.all()
    const knownUsers = robot.brain.users()
    const addedUsers = []
    for (let user of allUsers) {
      if (knownUsers[user._id]) continue
      robot.brain.userForId(user._id, {
        name: user.username,
        alias: user.alias
      })
      addedUsers.push(user.username)
    }
    return addedUsers
  } catch (err) {
    robot.logger.error('Could not sync user data with bot', err)
  }
}

/**
 * Add command for bot to respond to requests for brain sync with added users.
 * e.g. "bot sync brain users" or "@bot sync users with brain"
 * @param {Robot} robot The Hubot instance
 */
function load (robot) {
  robot.respond(/^(sync users with brain|sync brain users)/i, async (res) => {
    const addedUsers = await syncBrainUsers(robot)
    if (typeof addedUsers === 'undefined') {
      res.reply(`Sorry I can't do that.`)
    } else {
      const names = '@' + addedUsers.join(', @').replace(/,(?!.*,)/gmi, ' and')
      res.reply(`${names} were added to my brain.`)
    }
  })
}

module.exports = {
  syncBrainUsers,
  load
}
