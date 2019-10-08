# Docker PHP Development Boilerplate

## Description

This allows you to quickly set up a PHP development environment complete with the following features: 

* Apache 2.4
* PHP 5.6 through 7.2
* MariaDB 10.3 or MySQL 8
* [XDebug](https://xdebug.org/)
* [MailCatcher](https://mailcatcher.me/)
* [Selenium](https://www.seleniumhq.org/)

It can be easily repurposed for other languages or frameworks by adding / altering container definition files. 

## Requirements

* [Docker Engine](https://www.docker.com/get-started) 1.10.0 or higher

## Pre-requisites

1. Install and launch Docker Engine

2. Confirm that it is running: 

```bash
$ docker version
```

```bash
Client:
 Version:      18.03.1-ce
 API version:  1.37
 Go version:   go1.9.5
 Git commit:   9ee9f40
 Built:        Thu Apr 26 07:13:02 2018
 OS/Arch:      darwin/amd64
 Experimental: false
 Orchestrator: swarm

Server:
 Engine:
  Version:      18.03.1-ce
  API version:  1.37 (minimum version 1.12)
  Go version:   go1.9.5
  Git commit:   9ee9f40
  Built:        Thu Apr 26 07:22:38 2018
  OS/Arch:      linux/amd64
  Experimental: true

```

## Usage

### Basic Usage

1. Clone this repository into a directory
 
2. Start with default settings 

```bash
$ docker/tools/start.sh 
```

This will launch a set of containers with default PHP / DB versions as specified in `start.sh` file. The first
run may take a while to download images and build containers. Subsequent runs should be significantly faster. 

3. Open the included test page: 

[http://localhost:8081/](http://localhost:8081/)

Click "Check Environment" to confirm PHP / DB versions: 

```
PHP version: 7.0.31

DB version: 10.3.9-MariaDB-1:10.3.9+maria~bionic

Click here to send a test email
```

Click the link provided to send a test email to be intercepted by a local instance of MailCatcher. Mail is 
processed by ssmtp - you can reconfigure it to mail to an external SMTP server instead, if desired.

To stop containers, just press Ctrl-C in the terminal.

If you need to get to the root command prompt in the web container, do this in another terminal: 

```bash
$ docker/tools/shell.sh 
```

If everything is broken, use "The Panic Button" - it will stop, reset and rebuild all containers:

```bash
$ docker/tools/start.sh --reset 
``` 

##### NOTE: If you have any data in databases inside the DB container, it will be lost when DB container is reset.

### Development

Docker web container will map everything in the top directory to be served from `http://localhost:8081`. E.g.
the bundled page located at `/dev/phpinfo.php` is accessible here: 

[http://localhost:8081/dev/phpinfo.php](http://localhost:8081/dev/phpinfo.php)

Start by removing index.html and replacing it with your app entry point. You can also remove `/env/` folder or
keep it for further reference. 

### Deployment

When packaging your software for deployment, remove `/env`, `/docker` and any other folders not directly 
required to run your application.  

As a separate reminder, take care to NOT deploy your .git folder to be publicly served by a web server. 
Do not be that person.

### XDebug

[XDebug](https://xdebug.org/) is a PHP debugger extension that is supported by PhpStorm and other IDEs. It is
enabled by default but can be disabled if required - edit `docker/files/php/ext-xdebug.ini` and change 
`xdebug.remote_enable` setting to `0`, then restart the environment with `--build` option:

```bash
$ docker/tools/shell.sh --build 
```

### MailCatcher

All mail sent from PHP will be routed to a local instance of MailCatcher. Note that MailCatcher runs in a separate
container from the web server (see `docker/docker-compose.yml` file for `mailcatcher` service). 
To access MailCatcher console and inspect emails sent, open the following URL in your browser:

[http://localhost:1080/](http://localhost:1080/)

MailCatcher has a [REST API](https://mailcatcher.me/) that you can use in your tests to assert 
proper mail delivery. 

Get all messages: 

[http://localhost:1080/messages](http://localhost:1080/messages)

Retrieve message with `id` of 1:

[http://localhost:1080/messages/1.json](http://localhost:1080/messages/1.json)

## Advanced Usage

### Using a different PHP version

Use command line flags to alter the PHP version you want to use: 

```bash
$ docker/tools/start.sh --php 72
```

Available PHP versions are `56`, `70`, `71` and `72`. Adding new ones should be as easy as duplicating e.g.
`docker/dockerfiles/Dockerfile.php72.web` file, renaming it accordingly and changing the first line to reflect
the desired PHP version. 

The above command will run PHP 7.2. Note that start script saves the most recent version of PHP run and should 
automagically rebuild the web Docker container on PHP version change. If this fails for any reason and you are
stuck on a previous PHP version, do a forced rebuild:

```bash
$ docker/tools/start.sh --php 72 --build
```

### Using a different DB engine

Use command line flags to alter the DB engine you want to use: 

```bash
$ docker/tools/start.sh --db mysql8
```

Available DB engines are `mariadb103` and `mysql8`. Similar to PHP versions, duplicating, renaming and editing 
e.g. `docker/dockerfiles/Dockerfile.mysql8.db` file allows adding a new DB engine.

The above command run MySQL 8. Note that start script saves the most recent DB engine run and should 
automagically reset the DB Docker container if required. A full container reset is required because different
DB engines may / will have incompatible DB file formats.   

### Note that a DB engine change WILL erase all databases managed by the DB container!

If you need to retain your DB data, dump all databases first and reimport the dump into the new DB engine 
after the switch.  

If the automatic reset fails for any reason and DB fails to start (as evident from the console output when doing
`start.sh`), do a forced reset:

```bash
$ docker/tools/start.sh --db mysql8 --reset
```

## Selenium

The Selenium container is provided as a demonstration of convenient, isolated and portable testing environment.
