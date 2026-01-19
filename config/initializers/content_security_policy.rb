# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https

    # Allow @vite/client to hot reload javascript changes in development
    if Rails.env.development?
      policy.script_src *policy.script_src, :unsafe_eval, :unsafe_inline, "http://localhost:3036"
      policy.connect_src :self, :wss, :ws, "http://localhost:3036", "ws://localhost:3036"
    else
      # Allow WebSocket connections for ActionCable in production/test
      policy.connect_src :self, :wss, :ws
    end

    # Allow blob: for test environment if needed
    policy.script_src *policy.script_src, :blob if Rails.env.test?

    policy.style_src :self, :https
    # Allow @vite/client to hot reload style changes in development
    policy.style_src *policy.style_src, :unsafe_inline if Rails.env.development?

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
