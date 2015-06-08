# hubot-rocketchat

Good news!  Rocket.Chat is ready for your bots *NOW*!  

Docker containers make (the usually complicated) setup a breeze.  Follow the quick start guide below to launch your bot.

### Quickstart guide for bot writers

You will need:

* node.js 
* git
* docker

First, clone this project.

```
git clone https://github.com/RocketChat/hubot-rocketchat.git
```

Change into the directory and install the dependencies.

```
cd hubot-rocketchat
npm install
```

Configure your bot - see **Additonal details** below.

Run the docker container, and your bot is LIVE!
```
docker run -it --rm -v $PWD:/home/hubot/node_modules/hubot-rocketchat -v $PWD/scripts:/home/hubot/scripts singli/hubot-rocketchat
```


### Verify your bot is working
Try:
```
rocketbot ping
```

And:
```
rocketbot help
```
The example bot under `scripts` directory respeonds to:
```
rocketbot report status
```


#### Additional details
Look under the `scripts` directory, you will find a very basic bot there.   

Just add your own bot in the directory to have it loaded.  If you are new to bot writing, [this single page](https://hubot.github.com/docs/scripting/) contains everything you need to know.

Obviously, you also need:

* a user in Rocket.Chat that the bot will run under
* a room including the bot user as a member

Edit the src/meteorchat.coffee file to set:

Variable | Description
:---- | :----
_meteorurl | the IP and port where Rocket.Chat is running
_hubotuser | the bot user's name
_hubotpassword | the bot user's password
_roomid | the channel that the bot should join, take a look at the end of your URL while inside a room to get the id

We are continually enhancing this hubot to Rocket.Chat adapter, any bot you write should remain compatible as we add capabilities to the adapter
If you find a bug or compatibility problem, please submit an issue.  If you have any enhancements or feature requests, submit an issue.  If you like what you see, please star the repo.

Finally, if you have created a bot that other users may find useful, please contribute it.


#### Some important notes

* The first time you run the docker container, the image needs to be pulled from the public docker registry and it will take some time.  Subsequent runs are super fast.
* If you are not running Linux (i.e. if you are on a Mac or PC), you cannot use $PWD to mount the volumes.  Instead, [read this note here](https://docs.docker.com/userguide/dockervolumes/) (the 2nd note on the page: *If you are using Boot2Docker...*) to determine the absolute path where you must place the git-cloned directory.   

### CONTRIBUTORS WANTED

While it is functional, the current adapter is very basic.  We need all the help we can get to add capabilities.  

Become part of the project, just pick an issue and file a PR.

The adapter code is under the `src` directory.   To test changed adapter code, just simply stop the container and run it again.


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
This command specifies a distribution of test bot instances across globally located data centers.  

Once received, the bot:
* parses the distribution
* concurrently ssh to remote kubernetes controllers and spwans the specified number of test bot instances to start the load test

Q:   The architecture of hubot-rocketchat looks interesting, can you tell me more about it?

A:  Sure, it is based on hubot-meteorchat.  hubot-meteorchat is the hubot integration project for Meteor based chats and real-time messaging systems.  Its driver based architecture simplifies creation and cusotmization of adapter for new systems. For example, the hubot-rocketchat integration is just hubot-meteorchat + rocketchat driver.

Learn more about hubot-meteorchat and other available drivers [at this link](https://github.com/Sing-Li/hubot-meteorchat).



#### If for some reasons, you can not run docker.  Following are some old notes to help you get up and running.

##### Setting up Rocket.Chat for hubot-rocketchat adapter development

Note the current implementation is far from complete.  This working adapter allows contributors to start hacking asap.


##### Manual configuration 

On your Rocket.Chat server, create a new user named hubot, and set password to hubot - choose your own avatar.  (you can change the username or password in the src/meteorchat.coffee file)

Logon as another user, create a new channel and add hubot as a user.  While in that channel, look at your browser's URL - note the random alpha at the end, that is the room-id of the channel.  Cut the roomid and paste it into _roomid of src/meteorchat.coffee.

##### Install hubot and link adapter

In this hubot-rocketchat  directory:

```
npm install
```

Instantiate a hubot instance using yeoman by following [these instructions](https://hubot.github.com/docs/)


Configure the adapter development environment by following [these instructions](https://hubot.github.com/docs/adapters/development/).  Link it, but don't run the bot just yet.

Now check the relative path in the first line in src/meteorchat.coffee and make sure you are pointing to the source directory of hubot.

Make sure you have a REDIS instance running locally. See [these instructions](http://redis.io/topics/quickstart)

Finally, run your bot:
```
hubot -a rocketchat 

```

