WOW: Wafflehaüs' Organized Workspace!
================

This is the Meteor app that coordinates solving for the MIT Mystery Hunt team affiliated with Simmons Hall. Officially, our name is Wafflehaüs, although we occasionally go by Simhunt. 

This app is based on [Galackboard](https://github.com/Galactic-Infrastructure/galackboard) (developed by ✈﻿✈﻿✈ Galactic Trendsetters ✈﻿✈﻿✈), which in turn is based on the Codex [Blackboard](https://github.com/cjb/codex-blackboard) (developed by Codex).

The app is a work in progress. Proceed with caution.
  
Developing
==========

To run in development mode:

    $ cd wow
    $ meteor --settings private/settings.json
    <browse to localhost:3000>

The settings.json file has the following structure:
```
{
    "key": the RSA private key for a Google Cloud service account,
    "email": the email address for the Google Cloud service account,
    "folder": a name for the Google Drive folder that you want to use for this deployment;
              can be shared by using the dropdown menu at the top right of the app
              (note that this is NOT a folder ID--it is a name for a new folder that will
              be created by the service account),
    "template": the Google Drive ID of the spreadsheet that is being used 
    			as a template to create other spreadsheets,
    "discordToken": the token for a Discord bot,
    "discordServerName": the server name that the Discord bot should listen to,
    "teampassword": the password that people who visit the app must enter to use it
}
```
For the contents of the `settings.json` file which actually make Google Drive and Discord integration work, contact Jenna Himawan.

If you're running under Windows Subsystem for Linux, and you want to use your
Windows partition for the git repo (e.g. so you can use the native GitHub
client and/or graphical editors) you will need to mount a directory on the
virtual Linux filesystem as .meteor/local. You will also need to store your
settings.json file on the virtual Linux filesystem.

## Installing Meteor

Our blackboard app currently uses Meteor 2.2.

At the moment the two ways to install Meteor are:

* just make a git clone of the meteor repo and put it in $PATH, or
* use the package downloaded by their install shell script

The latter option is easier, and automatically downloads the correct
version of meteor and all its dependencies, based on the contents of
`simhunt/.meteor/release`.  Simply cross your fingers, trust
in the meteor devs, and do:

    $ curl https://install.meteor.com | /bin/sh

You can read the script and manually install meteor this way as well;
it just involves downloading a binary distribution and installing it
in `~/.meteor`.

If piping stuff from the internet directly to `/bin/sh` gives you the
willies, then you can also run from a git checkout.  Something like:

    $ cd ~/3rdParty
    $ git clone git://github.com/meteor/meteor.git
    $ cd meteor
    $ git checkout release/METEOR@1.0
    $ cd ~/bin ; ln -s ~/3rdParty/meteor/meteor .

Meteor can run directly from its checkout, and figure out where to
find the rest of its files itself --- but it only follows a single symlink
to its binary; a symlink can't point to another symlink.  If you use a
git checkout, you will be responsible for updating your checkout to
the latest version of meteor when `simhunt/.meteor/release`
changes.

You should probably watch the screencast at http://meteor.com to get a sense
of the framework; you might also want to check out the examples they've
posted, too.

## Publishing to Prod
WOW is usually run on an mit.edu subdomain (URL not provided for safety reasons). This subdomain is owned by <simmons-tech@mit.edu>. To have your private key added so that you can publish to that subdomain, please contact them.

### Deployment to a Simmons-owned Server

Publishing is done via [Meteor Up](http://meteor-up.com), aka `mup`. Installation instructions can be found [here](http://meteor-up.com/docs.html#installation). For the actual contents of `.deploy/mup.js` or `.deploy/settings.js`, contact Jenna Himawan.

Useful `mup` commands (all done from `.deploy` folder):
 - to restart meteor project:
    - `mup restart`
 - to deploy meteor project:
    - `mup deploy`
 - to reset database:
    - `mup mongo shell`
    - `use app`
    - `db.dropDatabase()`
 - to see logs in real time:
    - `mup logs -f`

## Discord Integration

To add DAPHNE to a new Discord server (aka guild), a member of the Simhunt Discord Developer Organization must visit `https://discord.com/api/oauth2/authorize?client_id=[CLIENT_ID]&permissions=8&scope=applications.commands%20bot` in a browser and log in.
 - `CLIENT_ID` is DAPHNE's application ID, which is found under General Information from the Bot Management page
 - `permissions=8` gives DAPHNE Administrator status in the guild. We could probably use narrower permissions, but I don't really see a reason to make things complicated.
 - `scope=applications.commands%20bot` allows DAPHNE's developers to register slash commands for her. The `bot` part is there for reasons I don't understand. Discord API magic.