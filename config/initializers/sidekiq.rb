require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }
end

Sidekiq.default_worker_options = {
  'backtrace' => true,
  'retry'     => false
}

schedule_file = "config/schedule.yml"
# Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file) # && Sidekiq.server?

unless Rails.env.test?
  Sidekiq::Logging.logger.level = Logger::DEBUG
  Rails.logger                  = Sidekiq::Logging.logger
end
