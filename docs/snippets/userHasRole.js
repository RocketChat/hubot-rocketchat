/**
 * Use API to check if role exists on given user.
 * Bot requires `view-full-other-user-info` permission.
 * Test with `node docs/snippets userHasRole` from project room.
 * @param {Robot} robot        Hubot instance
 * @param {User} user          Hubot user object containing name
 * @param {string} role        Role to check for in roles array
 * @return {boolean|undefined} If user has the role
 */
async function userHasRole (robot, user, role) {
  try {
    robot.logger.info(`[userHasRole] checking if ${user.name} has ${role} role`)
    const info = await robot.adapter.api.get('users.info', { username: user.name })
    if (!info.user) throw new Error('No user data returned')
    if (!info.user.roles) throw new Error('User data did not include roles')
    return (info.user.roles.indexOf(role) !== -1)
  } catch (err) {
    robot.logger.error('Could not get user data with bot, ensure it has `view-full-other-user-info` permission', err)
  }
}

/**
 * Add command for bot to respond to requests for a role check on a user.
 * e.g. "Hubot is admin an admin?" or "@bot is bot a bot" - both reply true.
 * @param {Robot} robot The Hubot instance
 */
function load (robot) {
  robot.respond(/\bis (.*) an? (.*?)\??$/i, async (res) => {
    const name = res.match[1]
    const role = res.match[2]
    const hasRole = await userHasRole(robot, { name }, role).catch()
    if (typeof hasRole === 'undefined') {
      res.reply(`Sorry, I can't do that.`)
    } else {
      res.reply((hasRole)
        ? `Yes, @${name} has the \`${role}\` role.`
        : `No, @${name} does not have the \`${role}\` role.`
      )
    }
  })
}

module.exports = {
  userHasRole,
  load
}
