# Be sure to restart your server when you modify this file.

  Rails.application.config.session_store :cookie_store, key: '_aicrowd_session', domain: URI.split(ENV['DOMAIN_NAME'])[2].delete_prefix("www.")
