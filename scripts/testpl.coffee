# Description:
#   Poltava News
#
# Dependencies:
#   "nodepie": "0.5.0"
#
# Configuration:
#   None
#
# Commands:
#   hubot pl top <N> - get the top N items on poltava news (or your favorite RSS feed)
#   pl.top - refer to the top item on pl
#   pl[i] - refer to the ith item on pl
#
# Author:
#   noname

NodePie = require("nodepie")

plFeedUrl = "https://poltava.to/rss/news.xml"

module.exports = (robot) ->
  robot.respond /pl top (\d+)?/i, (msg) ->
    msg.http(plFeedUrl).get() (err, res, body) ->
      if res.statusCode is not 200
        msg.send "Something's gone awry"
      else
        feed = new NodePie(body)
        try
          feed.init()
          count = msg.match[1] || 5
          items = feed.getItems(0, count)
          msg.send item.getTitle() + ": " + item.getPermalink() + " (" + item.getComments()?.html + ")" for item in items
        catch e
          console.log(e)
          msg.send "Something's gone awry"

  robot.hear /pl(\.top|\[\d+\])/i, (msg) ->
     msg.http(plFeedUrl).get() (err, res, body) ->
       if res.statusCode is not 200
         msg.send "Something's gone awry"
       else
         feed = new NodePie(body)
         try
           feed.init()
         catch e
           console.log(e)
           msg.send "Something's gone awry"
         element = msg.match[1]
         if element == "pl.top"
           idx = 0
         else
           idx = (Number) msg.match[0].replace(/[^0-9]/g, '') - 1
         try
           item = feed.getItems()[idx]
           msg.send item.getTitle() + ": " + item.getPermalink() + " (" + item.getComments()?.html + ")"
         catch e
           console.log(e)
msg.send "Something's gone awry"
