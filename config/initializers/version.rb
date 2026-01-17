Rails.application.config.app_version = ENV["APP_VERSION"].presence || "1.0.0"
Rails.application.config.git_revision = ENV["GIT_REVISION"]
