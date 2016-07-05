OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  # provider :oauth_provider,
  # Rails.application.secrets.oauth_provider_client_id,
  # Rails.application.secrets.oauth_provider_client_secret,
  # {provider_ignores_state: true, environment: Rails.env}
end