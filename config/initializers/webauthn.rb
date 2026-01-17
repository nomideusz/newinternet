# WebAuthn configuration for New Internet
# Passwordless authentication using passkeys

WebAuthn.configure do |config|
  # Allowed origins for WebAuthn ceremonies (full URLs with scheme + host + port)
  config.allowed_origins = [ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000")]
  
  # Relying Party name (displayed to users during passkey creation)
  config.rp_name = "New Internet"
  
  # Relying Party ID (typically the domain without port)
  config.rp_id = ENV.fetch("WEBAUTHN_RP_ID") { URI.parse(config.allowed_origins.first).host }
end
