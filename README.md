![Rocket.Chat logo](https://rocket.chat/images/logo/logo-dark.svg?v3)

[![Rocket.Chat](https://open.rocket.chat/api/v1/shield.svg?type=channel&name=Rocket.Chat&channel=hubot)](https://open.rocket.chat/channel/hubot)
[![Test Coverage](https://codeclimate.com/github/RocketChat/hubot-rocketchat/badges/coverage.svg)](https://codeclimate.com/github/RocketChat/hubot-rocketchat/coverage)
[![Code Climate](https://codeclimate.com/github/RocketChat/hubot-rocketchat/badges/gpa.svg)](https://codeclimate.com/github/RocketChat/hubot-rocketchat)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/RocketChat/Rocket.Chat/raw/master/LICENSE)

# hubot-rocketchat

Hubot adapter for Rocket.Chat!

Feel free to join us in the [#hubot](https://open.rocket.chat/channel/hubot) channel to discuss hubot, and any scripts you might be working on.

## Important

The latest version of the adapter is only compatible with 0.37.1 and higher of Rocket.Chat Server.

If you are using Rocket.Chat  0.35.0 or earlier, please use v0.1.4 of the adapter.  (releases between 0.35.0 and 0.37.1 are not recommended for hubot operations) 

#### NOTE
If you want to integrate Rocket.Chat with GitHub or GitLab.  Make sure you visit the [Rocket.Chat.Ops](https://github.com/RocketChat/Rocket.Chat.Ops) project before starting. We already have many scripts that add webhook events and access GitHub/GitLab APIs. You can easily extend these scripts for your custom application.

## Getting your bot connected to Rocket.Chat

Here is a sample run:

![picture of a sample interaction with rocketbot](https://raw.githubusercontent.com/Sing-Li/bbug/master/images/botpic.png)

We have a couple of ways for you to get up and started with the Rocket.Chat adapter.

### Docker

You can quickly spin up a docker image with:

```
docker run -it -e ROCKETCHAT_URL=<your rocketchat instance>:<port> \
	-e ROCKETCHAT_ROOM='' \
	-e LISTEN_ON_ALL_PUBLIC=true \
	-e ROCKETCHAT_USER=bot \
	-e ROCKETCHAT_PASSWORD=bot \
	-e ROCKETCHAT_AUTH=password \
	-e BOT_NAME=bot \
	-e EXTERNAL_SCRIPTS=hubot-pugme,hubot-help \
	rocketchat/hubot-rocketchat
```

#### Custom Scripts

If you want to include your own custom scripts you can by doing:

```
docker run -it -e ROCKETCHAT_URL=<your rocketchat instance>:<port> \
	-e ROCKETCHAT_ROOM='' \
	-e LISTEN_ON_ALL_PUBLIC=true \
	-e ROCKETCHAT_USER=bot \
	-e ROCKETCHAT_PASSWORD=bot \
	-e ROCKETCHAT_AUTH=password \
	-e BOT_NAME=bot \
	-e EXTERNAL_SCRIPTS=hubot-pugme,hubot-help \
	-v $PWD/scripts:/home/hubot/scripts \
	rocketchat/hubot-rocketchat
```

### Docker-compose

If you want to use docker-compose for this task, add this for v0.1.4 adapter (this must be inserted in your docker-compose.yml):

```
# hubot, the popular chatbot (add the bot user first and change the password before starting this image)
hubot:
  image: rocketchat/hubot-rocketchat:v0.1.4
  environment:
    - ROCKETCHAT_URL=your-rocket-chat-instance-ip:3000 (e.g. 192.168.2.240:3000)
    - ROCKETCHAT_ROOM=
    - LISTEN_ON_ALL_PUBLIC=true
    - ROCKETCHAT_USER=username-of-your-bot
    - ROCKETCHAT_PASSWORD=yourpass
    - BOT_NAME=bot
    - GOOGLE_API_KEY=yourgoogleapikey
# you can add more scripts as you'd like here, they need to be installable by npm
    - EXTERNAL_SCRIPTS=hubot-help,hubot-seen,hubot-links,hubot-diagnostics,hubot-google,hubot-reddit,hubot-bofh,hubot-bookmark,hubot-shipit,hubot-maps
  links:
    - rocketchat:rocketchat
# this is used to expose the hubot port for notifications on the host on port 3001, e.g. for hubot-jenkins-notifier
  ports:
    - 3001:8080
```

 If you wish that your bot listen to all public rooms and all private rooms he is joined to let the env "ROCKETCHAT_ROOM" empty like in the example above and set the env "LISTEN_ON_ALL_PUBLIC" to true.
 
 Please take attention to some external scripts that are in the example above, some of them need your Google-API-Key in the docker compose file.

### Add adapter to hubot

#### New install
You can specify the adapter during setup.

First you need to install hubot

```
npm install -g yo generator-hubot
```

Then you need to start the setup of the bot

```
mkdir myhubot
cd myhubot
yo hubot --adapter="rocketchat@1"
```

It'll ask you a few questions.

Alternatively you can actually answer the questions in one command:

```
yo hubot --owner="OWNER <owner@example.com>" --name="bot" --description="Bot" --adapter="rocketchat@0.1"
```

Also be sure to remember the name you specify.  This is what the bot will respond to in Rocket.Chat.

You will need to tell the adapter where your install is and what login information to use.

```
export ROCKETCHAT_ROOM=''
export LISTEN_ON_ALL_PUBLIC=true
export ROCKETCHAT_USER=bot
export ROCKETCHAT_PASSWORD=bot
export ROCKETCHAT_AUTH=password
```

Then start with: `bin/hubot -a rocketchat`

[More Info Here](https://hubot.github.com/docs/)

#### Existing install
If you already have hubot setup you can add the adapter.

By doing: `npm install hubot-rocketchat@1`

You will need to tell the adapter where your install is and what login information to use.

```
export ROCKETCHAT_ROOM=''
export LISTEN_ON_ALL_PUBLIC=true
export ROCKETCHAT_USER=bot
export ROCKETCHAT_PASSWORD=bot
export ROCKETCHAT_AUTH=ldap
```

Then starting your bot specifying the adapter: `bin/hubot -a rocketchat`

#### Configuration Options

Here are all of the options you can specify to configure the bot.

On Docker you use: `-e VAR=Value`

Regular hubot via: `export VAR=Value` or add to pm2 etc

Environment Variable | Description
:---- | :----
ROCKETCHAT_URL | the URL where Rocket.Chat is running, can be specified as `host:port` or `http://host:port`  or `https://host:port`. If you are using `https://`, you **MUST** setup websocket pass-through on your reverse proxy (NGINX, and so on) with a valid certificate (not self-signed).  Directly accessing Rocket.Chat without a reverse proxy via `https://` is not possible.
ROCKETCHAT_USER | the bot user's name. It must be a registered user on your Rocket.Chat server, and the user must be granted `bot` role via Rocket.Chat's administrator's panel  (note that this will also be the name that you can summon the bot with)
ROCKETCHAT_PASSWORD | the bot user's password
ROCKETCHAT_AUTH | defaults to 'password' if undefined, or set to 'ldap' if your use LDAP accounts for bots.
ROCKETCHAT_ROOM | the channel/channels names the bot should listen to message from.  This can be comma separated list.
LISTEN_ON_ALL_PUBLIC | if 'true' then bot will listen and respond to messages from all public channels, as well as respond to direct messages. Default to 'false'. ROCKETCHAT_ROOM should be set to empty (with `ROCKETCHAT_ROOM=''` ) when using `LISTEN_ON_ALL_PUBLIC`. *IMPORTANT NOTE*:  This option also allows the bot to listen and respond to messages _from all newly created private groups_ that the bot's user has been added as a member.
RESPOND_TO_DM | if 'true' then bot will respond to direct messages. When setting the option to 'true', be sure to also set ROCKETCHAT_ROOM or LISTEN_ON_ALL_PUBLIC.  Default is 'false'.
RESPOND_TO_EDITED | if 'true' then bot will respond to edited messages. Default is 'false'.
ROOM_ID_CACHE_SIZE | The maximum number of room IDs to cache. You can increase this if your bot usually sends messages to a large number of different rooms. Default value: 10
DM_ROOM_ID_CACHE_SIZE | The maximum number of Direct Message room IDs to cache. You can increase this if your bot usually sends a large number of Direct Messages. Default value: 100
ROOM_ID_CACHE_MAX_AGE | Room IDs and DM Room IDS are cached for this number of seconds. You can increase this value to improve performance in certain scenarios. Default value: 300
BOT_NAME | ** Name of the bot.  This is what it responds to
EXTERNAL_SCRIPTS | ** These are the npm modules it will add to hubot.
HUBOT_LOG_LEVEL | hubot log level, string [debug|info|warning|error], default: info 

** - Docker image only.
##### Configuring the Bot to listen and respond to direct messages plus all new public channels and private groups

This is a common configuration for Rocket.Chat bot installations.

Use the following options:

`LISTEN_ON_ALL_PUBLIC=true`  and `ROCKETCHAT_ROOM=''`  and *do not* specify `RESPOND_TO_DM`

Be aware you *must* add the bot's user as a member of the new private group(s) before it will respond.

### Verify your bot is working
Try:
```
rocketbot ping
```

And:
```
rocketbot help
```
The example bot under `scripts` directory responds to:
```
rocketbot report status
```

## Developers

We like to make development as easy on ourselves as possible.  So passing the love on to you!

### Adapter Development
We'd love to have your help improving this adapter. PR's very welcome :smile:

#### Docker

First clone the source and then move into the directory.

```
git clone git@github.com:RocketChat/hubot-rocketchat.git
cd hubot-rocketchat
```

Now we start the docker container.

```
docker run -it -e ROCKETCHAT_URL=<your rocketchat instance>:<port> \
	-e ROCKETCHAT_ROOM='' \
	-e LISTEN_ON_ALL_PUBLIC=true \
	-e ROCKETCHAT_USER=bot \
	-e ROCKETCHAT_PASSWORD=bot \
	-e ROCKETCHAT_AUTH=password \
	-e BOT_NAME=bot \
	-e EXTERNAL_SCRIPTS=hubot-pugme,hubot-help \
	-v $PWD:/home/hubot/node_modules/hubot-rocketchat rocketchat/hubot-rocketchat
```

#### Standard

Installed in hubot you'd hop over into `node_modules`.

Delete the hubot-rocketchat folder.

Then clone the git repo.

```
git clone git@github.com:RocketChat/hubot-rocketchat.git
cd hubot-rocketchat
npm install
```

#### Additional details
Look under the `scripts` directory, you will find a very basic bot there.

Just add your own script in the directory to have it loaded.  If you are new to hubot script writing, find out more [here](https://hubot.github.com/docs/scripting/).

If you find a bug or compatibility problem, please open an issue.

If you have any enhancements or feature requests, create an issue.  If you like what you see, please star the repo.

Finally, if you have created a bot that other users may find useful, please contribute it.


#### Some important notes

* The first time you run the docker container, the image needs to be pulled from the public docker registry and it will take some time.  Subsequent runs are super fast.
* If you are not running Linux (i.e. if you are on a Mac or PC), you cannot use $PWD to mount the volumes.  Instead, [read this note here](https://docs.docker.com/userguide/dockervolumes/) (the 2nd note on the page: *If you are using Boot2Docker...*) to determine the absolute path where you must place the git-cloned directory.

### CONTRIBUTORS WANTED

While it is functional, the current adapter is very basic.  We need all the help we can get to add capabilities.

Become part of the project, just pick an issue and file a PR.

The adapter code is under the `src` directory.   To test modified adapter code, exit (ctrl-c) the container and run it again.


### FAQ

Q:  I am not trying to stage a denial of service attack, why would I ever want to write a bot?

A:  There are many positive and productive use cases for bots.    Imagine a customer service support chat.   As soon as a customer enters the support channel, a bot immediately identifies the customer and then:
* fetches recent sales information from the sales dept server
* fetches personal information from the customer data base
* fetches latest notes made by her/his salesperson from the CRM system
* scans the customer's facebook and twitter posts
* obtains details of the last support ticket for this customer

Putting it altogether and then private message the service rep with the information.

Another use-case is a load test bot, imagine a bot that accepts the command:

````
rocketbot loadtest europe 25, asia 50, usa 100, canada 10
````
This command specifies a distribution of test bot instances, to be created across globally located data centers.

Once received, the bot:
* parses the distribution
* concurrently ssh to remote Kubernetes controllers and spawns the specified number of test bot instances to start the load test

Q:   The architecture of hubot-rocketchat looks interesting, can you tell me more about it?

A:  Sure, it is based on hubot-meteorchat.  hubot-meteorchat is the hubot integration project for Meteor based chats and real-time messaging systems.  Its driver based architecture simplifies creation and customization of adapter for new systems. For example, the hubot-rocketchat integration is just hubot-meteorchat + Rocket.Chat driver.

Learn more about hubot-meteorchat and other available drivers [at this link](https://github.com/Sing-Li/hubot-meteorchat).
