OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :backstage,
  Rails.application.secrets.accounts_backstage_client_id,
  Rails.application.secrets.accounts_backstage_client_secret,
  {provider_ignores_state: true, environment: Rails.env}
end