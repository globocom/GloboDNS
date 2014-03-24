DNSAPI
======

Welcome to DNSAPI
-----------------

DNSAPI is a Ruby on Rails application designed to manage domain name services based on [Bind](https://www.isc.org/software/bind) with a RESTful API and using MySQL as persistent storage backend. 
The project is an adaptation of [PowerDNS-on-rails](https://github.com/kennethkalmer/powerdns-on-rails) developed by 
[Kenneth Kalmer](kenneth.kalmer@gmail.com) plus some features like UI, job queue and Bind specific importation script.

# Overview

The DNSAPI was designed to work with Bind in a passive way. Once you've configured the primary and slaves servers, database and executed the first importation of your records, all work is done between the application and the DB . Then all files are exported via Rsync tool to the Bind server(s) and any command is issued with Rndc utility.

# Motivations

##Security
	With multiple levels of privilege, we can ensure that a specific user is abble to perform only specific tasks.
	
##Integrity
	All actions are validated to prevent bad records or other undesirable human mistakes.
	
##Usability
	The UI provides a simplier way to manage the service.

## Features
	RESTful architecture
	Multi-user with groups of privilege
	Asychronous and synchronous tasks modes
	Conversion and import tools
	Zone/Record Templates
	Full audit record of all changes
	Macros for easy bulk updating of domains
	Support for Bind MASTER, NATIVE & SLAVE record types

## Installing

#### In order to install dnsapi into your enviroment you'll need to:
	* Clone the project into the desired path.
	* Run the command "bundle install" into the path to install the dependencies.
	* Within the file "config/globodns.yml" you will find all the configurantion parameters to make DNSAPI properly work with your own Bind specifications. You'll also find a list of binaries required to be installed on the server running the api.
	* Thus, still on globodns.yml file, you have a parameter called "export_(master|slave)_chroot_dir". This path need to be created manually, to handle version control and tmp file holder.
	* In config/database.yml you can set the suitable database for you.
	* On the bind server, the user running the api, need to have the same uid and gid and also be member of the Bind (named daemon) group.
	* Note: DNSAPI process the files on your own machine and then transfer the desired files already modified through rsync to the bind server. So you need to make this access possible and take care with your specific file permissions.
	* Then you can setup up your favourite webserver and your preferred plugin (i.e. apache + passenger).
* For API specific information you can access the [Wiki](https://github.com/globocomgithub/DNSAPI/wiki/API)