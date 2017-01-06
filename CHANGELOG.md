# Changelog

## [1.5.12](https://github.com/globocom/GloboDNS/releases/tag/1.5.12) (05/01/17)
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


