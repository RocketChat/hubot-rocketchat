FROM node:8.11.2-alpine
LABEL maintainer="Rocket.Chat Team <buildmaster@rocket.chat>"

ENV npm_config_loglevel=error

USER root

COPY bin/hubot /home/hubot/bin/
COPY scripts /home/hubot/scripts
COPY package.json /home/hubot/

RUN apk add --update --no-cache \
    git && \
    adduser -S hubot && \
    addgroup -S hubot && \
    touch ~/.bashrc && \
    npm i -g npm@latest && \
    chown -R hubot:hubot /home/hubot/

WORKDIR /home/hubot/

ENV BOT_OWNER "No owner specified"
ENV BOT_DESC "Hubot with the Rocket.Chat adapter"

#ENV EXTERNAL_SCRIPTS=hubot-diagnostics,hubot-google-images,hubot-google-translate,hubot-pugme,hubot-maps,hubot-rules,hubot-shipit

USER hubot


RUN npm install 

CMD ["/bin/ash", "/home/hubot/bin/hubot"]
