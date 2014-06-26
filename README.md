DNSAPI
======

Welcome to DNSAPI
-----------------

DNSAPI is a Ruby on Rails application designed to manage domain name services based on [Bind](https://www.isc.org/software/bind) with a RESTful API and using MySQL as persistent storage backend. 
The project is an adaptation of [PowerDNS-on-rails](https://github.com/kennethkalmer/powerdns-on-rails) developed by 
[Kenneth Kalmer](kenneth.kalmer@gmail.com) plus some features like UI, job queue and Bind specific importation script.

# Overview

The DNSAPI was designed to work with Bind in a passive way. Once you've configured the primary and slaves servers, database and executed the first importation of your records, all work is done between the application and the DB . Then all files are exported via Rsync tool to the Bind server(s) and any command is issued with Rndc utility.

Bellow: Some screenshots from the admin user.

*image1: Show domain details*

![Add a new domain form](doc/img/domain_details.png "Add a new domain form")

*image2: add a new domain*

![Add a new domain form](doc/img/new_domain_no_template.png "Add a new domain form")

*image3: add a new record*

![Add a new record](doc/img/create_record.png "Add a new record")

*image4: Listing lasts operations on Dns-Api*

![Listing lasts actions on Dns-Api](doc/img/logs.png "Listing lasts actions on Dns-Api")

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

Documentation
=============

[Setup your environment](./doc/setup.md)

[Administrator's Guide](./doc/administrator.md)

[API](https://github.com/globocom/Dns-Api/wiki/API)
