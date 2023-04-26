# GloboDNS API Client

A simple Python script to interact with the GloboDNS API.

## Requirements

- Python 3.x
- `requests` library

## Installation

1. Install the `requests` library:


2. Download the `api_client.py` script to your project directory.

## Usage

1. Import the `GloboDnsApiClient` class from the `api_client.py` script.

2. Create an instance of the `GloboDnsApiClient` class with your API base URL, email, and password.

3. Call the methods corresponding to the API endpoints. For example:

```python
from api_client import GloboDnsApiClient

client = GloboDnsApiClient("https://example.com", "your@email.com", "your_password")

# Get all domains
domains = client.get_domains()
print(domains)

# Get a specific domain
domain_id = 1
domain = client.get_domain(domain_id)
print(domain)

# Get records for a specific domain
records = client.get_records(domain_id)
print(records)

# Get a specific record
record_id = 1
record = client.get_record(record_id)
print(record)

# Get all domain templates
domain_templates = client.get_domain_templates()
print(domain_templates)

# Get record templates for a specific domain template
domain_template_id = 1
record_templates = client.get_record_templates(domain_template_id)
print(record_templates)

# Get BIND9 configuration
bind9_config = client.get_bind9_config()
print(bind9_config)

# Get health check status
healthcheck = client.get_healthcheck()
print(healthcheck)

