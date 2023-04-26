import requests

class GloboDnsApiClient:
    def __init__(self, base_url, email, password):
        self.base_url = base_url
        self.session = requests.Session()
        self.email = email
        self.password = password
        self._authenticate()

    def _authenticate(self):
        url = f"{self.base_url}/users/sign_in"
        data = {"user": {"email": self.email, "password": self.password}}
        response = self.session.post(url, json=data)
        response.raise_for_status()

    def get_domains(self):
        url = f"{self.base_url}/domains"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def get_domain(self, domain_id):
        url = f"{self.base_url}/domains/{domain_id}"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def get_records(self, domain_id):
        url = f"{self.base_url}/domains/{domain_id}/records"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def get_record(self, record_id):
        url = f"{self.base_url}/records/{record_id}"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def get_domain_templates(self):
        url = f"{self.base_url}/domain_templates"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def get_record_templates(self, domain_template_id):
        url = f"{self.base_url}/domain_templates/{domain_template_id}/record_templates"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def get_bind9_config(self):
        url = f"{self.base_url}/bind9/config"
        response = self.session.get(url)
        response.raise_for_status()
        return response.text

    def get_healthcheck(self):
        url = f"{self.base_url}/healthcheck"
        response = self.session.get(url)
        response.raise_for_status()
        return response.text

