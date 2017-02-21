# Changelog

## [1.5.24](https://github.com/globocom/GloboDNS/releases/tag/1.5.24) (21/02/17)
#### - Bug fixies
 * Record search field had the same name as domain search field
#### - Enhancements
 * Supporting the use of views
 * Task to migrate viewless zones to a default view (when using view, all zones must be in views)
 * Adding filed 'schedule_date' to 'Schedule Export' JSON output

## [1.5.19](https://github.com/globocom/GloboDNS/releases/tag/1.5.19) (07/02/17)
##### - Bug fixies 
 * Validation of record TXT was being applied to all record types
 * SRV record must have 'Priority', 'Weight' and 'Port' fields
##### - Enhancements 
 * Changed subject exporter/importer mailer, so that the emails received of different environments won't be agrouped

## [1.5.14](https://github.com/globocom/GloboDNS/releases/tag/1.5.14) (19/01/17)
##### - Enhancements
 * Support to use a different master ip in slaves.conf configurations

## [1.5.13](https://github.com/globocom/GloboDNS/releases/tag/1.5.13) (06/01/17)
##### - Bug fixes
 * CNAME validation
 * Records list pagination when querying
##### - Enhancements
 * TXT content validation - content must be strings of 255 caracters or less
 * CNAME content validation - content should be a record of its zone or a valid FQDN
 * Users search
 * Search audits by content

## [1.5.11](https://github.com/globocom/GloboDNS/releases/tag/1.5.11) (30/09/16)
##### - Enhancements
 * Add 'day' to time log filter 
 * User login and email are now only one text input


## [1.5.10](https://github.com/globocom/GloboDNS/releases/tag/1.5.10) (30/09/16)
##### - Enhancements
 * Logs filtering options


## [1.5.9](https://github.com/globocom/GloboDNS/releases/tag/1.5.9) (23/09/16)
##### - Bug fixes
 * Email notifing of import success or failure
 

##### - Enhancements 
 * User of type'Operator' cannot delete Domains



## [1.5.7](https://github.com/globocom/GloboDNS/releases/tag/1.5.7) (06/07/16)
##### - Bug fixes
 * Prevent 'Export all' to delete zones already removed
 * Fixed names validations of Records
 * Fixed zone type Forward creation
 * Fixed orthography
 * Fixed user interface bugs
 * Fixed SOA editing
 * Workaround for when the serial of the zone changes more than 100 times on the same day

##### - Enhancements 
 * Included changes and settings to optional use of OAuth login
 * Bind Views settings


