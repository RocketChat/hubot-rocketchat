// Description:
//   Cats' always like to mew.
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   hubot meow - < Sends you feline talk. >
//
// Notes:
//   Version 1.0
//
// Author:
//   munroenet | Cameron Munroe ~ Mun


/*
# The below example is in javascript writing.
# Below it is an example of a .coffee script 
# for comparison.

*/

module.exports = function(robot) {
  robot.respond(/meow/i, function(res) {
    res.send("Mew mew mew~");
  });
};


/*
# The below code is an example of a .coffee script.
# The purpose of this script is to show you the
# transormation to a .js script used by hubot.


module.exports = (robot) ->
  robot.respond /meow/i, (res) ->
    res.send "Mew mew mew~"

*/
