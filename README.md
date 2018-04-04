![Rocket.Chat logo](https://rocket.chat/images/logo/logo-dark.svg?v3)

[![Rocket.Chat](https://open.rocket.chat/api/v1/shield.svg?type=channel&name=Rocket.Chat&channel=bots)](https://open.rocket.chat/channel/bots)
[![Test Coverage](https://codeclimate.com/github/RocketChat/hubot-rocketchat/badges/coverage.svg)](https://codeclimate.com/github/RocketChat/hubot-rocketchat/coverage)
[![Code Climate](https://codeclimate.com/github/RocketChat/hubot-rocketchat/badges/gpa.svg)](https://codeclimate.com/github/RocketChat/hubot-rocketchat)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/RocketChat/Rocket.Chat/raw/master/LICENSE)

[hubot]: https://github.com/hubotio/hubot
[rocketchat]: https://github.com/RocketChat/Rocket.Chat
[rocketchat-ops]: https://github.com/RocketChat/Rocket.Chat.Ops
[bots-channel]: https://open.rocket.chat/channel/bots
[hubot-channel]: https://open.rocket.chat/channel/hubot
[hubot-rocketchat]: https://github.com/rocketchat/hubot-rocketchat
[hubot-rocketchat-coffee]: https://github.com/rocketchat/hubot-rocketchat/tree/coffeescript
[sdk]: https://github.com/rocketchat/Rocket.Chat.js.SDK
[contributing]: https://rocket.chat/docs/contributing/developing/
[issues]: https://github.com/RocketChat/hubot-rocketchat-boilerplate/issues
[generator]: https://github.com/hubotio/generator-hubot
[deployment]: https://hubot.github.com/docs/deploying/
[boilerplate]: https://github.com/RocketChat/hubot-rocketchat-boilerplate
[getting-started]: https://github.com/RocketChat/hubot-rocketchat-boilerplate#getting-started
[nvm]: https://github.com/creationix/nvm

# hubot-rocketchat

[Hubot][hubot] adapter for [Rocket.Chat][rocketchat]!

## Stable Versions

Version 2 of the adapter has been entirely refactored in Javascript ES6, for 
[Hubot v3][hubot], using the new [Rocketchat Node.js SDK][sdk] for Rocket.Chat
instances 0.60.0 onward.

If you are using Hubot v2, please use the last release of v1:
`hubot-rocketchat@1.0.12` on [the coffeescript branch][hubot-rocketchat-coffee]

<<<<<<< HEAD
Older versions of the adaptor (v0.*) are also incompatible with more recent
versions of Rocket.Chat (v0.35+). Please report an issue if you find specific 
version mismatches and we'll update this document.
=======
Feel free to join us in the [#hubot](https://open.rocket.chat/channel/hubot) channel to discuss hubot, and any scripts you might be working on.
>>>>>>> develop

## Discussion

Feel free to join us in the [#bots][bots-channel] channel to discuss hubot and
general bot support features in Rocket.Chat.

<<<<<<< HEAD
Our [#hubot][hubot-channel] channel is used for testing the internal hubot.
=======
If you are using Rocket.Chat  0.35.0 or earlier, please use v0.1.4 of the adapter.  (releases between 0.35.0 and 0.37.1 are not recommended for hubot operations)
>>>>>>> develop

#### NOTE

If you want to integrate Rocket.Chat with GitHub or GitLab. Make sure you visit
the [Rocket.Chat.Ops][rocketchat-ops] project before starting. We already have
many scripts that add webhook events and access GitHub/GitLab APIs. You can
easily extend these scripts for your custom application.

## Getting Started

### Creating a User

An admin user is required to create the account for the bot to login to.

1. From **Administration** > **Users** menu
2. Select `+` to make a new user
3. Enter *Name*, *Username*, *Email* (tick verified) and *Passwword*
4. Disable *Require password change*
5. Select `bot` from role selection and click *Add Role*
6. Disable *Join default channels* recommended, to avoid accidental listening
6. Disable *Send welcome email*
7. *Save*

Use these credentials in the bot's environment `ROCKETCHAT_USER` and
`ROCKETCHAT_PASSWORD`

Note that for bots email, a common workaround to avoid creating multiple
accounts is to use gmail +addresses, e.g. `youremail+botnam@gmail.com`.
[See this issue for more](https://github.com/RocketChat/Rocket.Chat/issues/7125)

### Existing Install

If you already have Hubot setup:

1. Add the adapter: `npm install hubot-rocketchat@2`
2. Set environment configs (see below)
3. Start your bot specifying the adapter: `bin/hubot -a rocketchat`

### Building a Bot

Please see our boilerplate bot [Getting Started docs here][getting-started]!

Note that the Yeoman generator does not currently use Hubot v3 and is
incompatible with hubot-rocketchat v2.

The boilerplate is essentially just a simple node package that requires Hubot,
the Rocket.Chat adapter and Coffeescript for its execution...

```
"dependencies": {
    "coffeescript": "^2.2.2",
    "hubot": "3",
    "hubot-rocketchat": "^2.0.0"
}
```

The bot can then be executed using a bin file in production, [as seen here](https://github.com/RocketChat/hubot-rocketchat-boilerplate/tree/master/bin).
Or via the package scripts locally using `npm run local` or `yarn local`

Using the boilerplate example, to start the bot in production, use
`bin/hubot -a rocketchat` - will install dependencies and run the bot with this
adapter.

[More info in Hubot's own docs here](https://hubot.github.com/docs/)

### Configuring Your Bot

In local development, the following can be set in an `.env` file. In production
they would need to be set on server startup.

| Env variable           | Description                                           |
| ---------------------- | ----------------------------------------------------- |
| `HUBOT_NAME`           | The programmatic name for listeners                   |
| `HUBOT_ALIAS`          | An alternate name for the bot to respond to           |
| `HUBOT_LOG_LEVEL`      | The minimum level of logs to output                   |
| `HUBOT_HTTPD`          | If the bot needs to listen to or make HTTP requests   |
| `HUBOT_ADAPTER`**      | The platform adapter package to require on loading    |
| `ROCKETCHAT_URL`*      | Local Rocketchat address (start before the bot)       |
| `ROCKETCHAT_USER`*     | Name in the platform (bot user must be created first) |
| `ROCKETCHAT_PASSWORD`* | Matching the credentials setup in Rocket.Chat         |
| `ROCKETCHAT_ROOM`      | The default room/s for the bot to listen in to        |
| `LISTEN_ON_ALL_PUBLIC` | Whether the bot should be listening everywhere        |
| `RESPOND_TO_DM`        | If the bot can respond privately or only in the open  |
| `RESPOND_TO_EDITED`    | If the bot should reply / re-reply to edited messages |

`*` Required settings

`**` Set to `rocketchat` to enable this adapter (or pass as launch argument)

 If you wish that your bot listen to all public rooms and all private rooms it
 is joined to let the env `ROCKETCHAT_ROOM` empty like in the example above and
 set the env `LISTEN_ON_ALL_PUBLIC` to true.

The Rocket.Chat adapter implements the Rocket.Chat Node.js SDK to call server
methods and selectively cache their results. For advanced usage, you may wish
to modify defaults for the SDK using it's environment settings, documented here:
https://github.com/rocketchat/rocket.chat.js.sdk#settings

##### Common configuration

It is common to set up a bot to listen and respond to direct messages and all
new public channels and private groups. Use the following options:
- `LISTEN_ON_ALL_PUBLIC=true`
- `ROCKETCHAT_ROOM=''`
- *do not* specify `RESPOND_TO_DM`

Be aware you *must* add the bot's user as a member of the new private group(s)
before it will respond.

## Connecting to Rocket.Chat

We have a couple of ways for you to get up and started with the adapter below.

### Docker

You can quickly spin up a docker image with:

```
docker run -it -e ROCKETCHAT_URL=<your rocketchat instance>:<port> \
	-e ROCKETCHAT_ROOM='' \
	-e LISTEN_ON_ALL_PUBLIC=true \
	-e ROCKETCHAT_USER=bot \
	-e ROCKETCHAT_PASSWORD=bot \
	-e HUBOT_NAME=bot \
	-e EXTERNAL_SCRIPTS=hubot-help,hubot-diagnostics \
	rocketchat/hubot-rocketchat
```

#### Custom Scripts

If you want to include your own custom scripts you can by doing:

```
docker run -it -e ROCKETCHAT_URL=<your rocketchat instance>:<port> \
	-e ROCKETCHAT_ROOM='' \
	-e LISTEN_ON_ALL_PUBLIC=true \
	-e ROCKETCHAT_USER=botname \
	-e ROCKETCHAT_PASSWORD=botpass \
	-e HUBOT_NAME=botname \
	-e EXTERNAL_SCRIPTS=hubot-help,hubot-diagnostics \
	-v $PWD/scripts:/home/hubot/scripts \
	rocketchat/hubot-rocketchat
```

### Docker-compose

If you want to use docker-compose for this task this must be inserted in your
docker-compose.yml:

```
# add the bot user first and change the password before starting this image
hubot:
  image: rocketchat/hubot-rocketchat:v0.1.4
  environment:
    - ROCKETCHAT_URL=your-rocket-chat-instance-ip:3000 (e.g. 192.168.2.240:3000)
    - ROCKETCHAT_ROOM=
    - LISTEN_ON_ALL_PUBLIC=true
    - ROCKETCHAT_USER=botname
    - ROCKETCHAT_PASSWORD=botpass
    - HUBOT_NAME=botname
# you can add more scripts here, they need to be installable by npm
    - EXTERNAL_SCRIPTS=hubot-help,hubot-diagnostics
  links:
    - rocketchat:rocketchat
# this is used to expose the hubot port for notifications on the host on port 3001, e.g. for hubot-jenkins-notifier
  ports:
    - 3001:8080
```

<<<<<<< HEAD
## Contributions Welcome

We'd love to have your help improving this adapter. PR's very welcome :smile:
=======
 If you wish that your bot listen to all public rooms and all private rooms he is joined to let the env "ROCKETCHAT_ROOM" empty like in the example above and set the env "LISTEN_ON_ALL_PUBLIC" to true.

 Please take attention to some external scripts that are in the example above, some of them need your Google-API-Key in the docker compose file.

### Alternative Node.js installation with [Node Version Manager](https://github.com/creationix/nvm) (nvm) in a local environment on Debian/Ubuntu

 ```
# adduser hubot
# su - hubot
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
$ exit
# su - hubot
$ nvm install v4.8.5
$ npm update -g
$ npm install -g yo generator-hubot
$ mkdir hubot
$ cd hubot
$ yo hubot (answer questions and use "rocketchat" as adapter)
$ npm install coffee-script -save
 ```
 Make sure ~/hubot/bin/hubot is executable: `chmod 755 ./bin/hubot`

 If you need a redis database: `apt install redis-server`

 Set node version: `export NODE_VERSION=default`

 If you want to start your hubot with [systemd](https://github.com/hubotio/hubot/blob/master/examples/hubot.service) use `nvm-exec`:

 ```
ExecStart=/home/hubot/.nvm/nvm-exec /home/hubot/hubot/bin/hubot --adapter rocketchat
 ```
 See EnvironmentFile directive for using environment variables in systemd units

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
>>>>>>> develop

Please see [our documentation on contributing][contributing], then
[visit the issues][issues] to share your needs or ideas.

### Development

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
	-e HUBOT_NAME=bot \
	-e EXTERNAL_SCRIPTS=hubot-help,hubot-diagnostic \
	-v $PWD:/home/hubot/node_modules/hubot-rocketchat rocketchat/hubot-rocketchat
```

#### Standard

In a Hubot instance once `hubot-rocketchat` is added by npm or yarn, you can
replace the package with a development version directly:

- `cd node_modules` from the bot's project root
- `rm -rf hubot-rocketchat` to delete the published version
- `git clone git@github.com:RocketChat/hubot-rocketchat.git` to add dev version
- `cd hubot-rocketchat` move to dev path
- `npm install` install dependencies

#### Linked

Setting up a locally linked package is easier for continued development and/or
using the same development version of the adapter in multiple bots.

- Change directory to your development adapter path
- `npm link` or `yarn link` to set the origin of the link
- Change directory to your bot's project root
- `npm link hubot-rocketchat` or `yarn link hubot-rocketchat` to create the link

#### Important notes

* The first time you run the docker container, the image needs to be pulled from
the public docker registry and it will take some time.  Subsequent runs are
super fast.
* If you are not running Linux (i.e. if you are on a Mac or PC), you cannot use
$PWD to mount the volumes. Instead, [read this note here](https://docs.docker.com/userguide/dockervolumes/)
(the 2nd note on the page: *If you are using Boot2Docker...*) to determine the
absolute path where you must place the git-cloned directory.
