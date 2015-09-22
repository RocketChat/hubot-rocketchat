# Description
#   A simple sample bot
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None

# Notes:
#   None
#
# Author:
#   Sing-Li <sli@makawave.com>

module.exports = (robot) ->
	robot.respond /report status/i, (res) ->
		res.reply "At your service!"
