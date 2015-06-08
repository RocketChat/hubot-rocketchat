FROM node:0.12.4
MAINTAINER Sing Li <sli@makawave.com>

RUN npm install -g coffee-script yo generator-hubot  &&  \
 useradd hubot -m

USER hubot

WORKDIR /home/hubot

RUN yo hubot --owner="S. Li <sli@makawave.com>" --name="rocketbot" --description="bot for adapter development" --defaults && \
 sed -i /heroku/d ./external-scripts.json && \
 sed -i /redis-brain/d ./external-scripts.json

CMD coffee -c /home/hubot/node_modules/hubot-rocketchat/src/*.coffee && \
bin/hubot -a rocketchat


