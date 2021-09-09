# Use this hook to configure merit parameters
Merit.setup do |config|
  # Check rules on each request or in background
  # config.checks_on_each_request = true

  # Add application observers to get notifications when reputation changes.
  config.add_observer 'ReputationChangeObserver'

  # Define :user_model_name. This model will be used to grant badge if no
  # `:to` option is given. Default is 'User'.
  config.user_model_name = 'Participant'

  # Define :current_user_method. Similar to previous option. It will be used
  # to retrieve :user_model_name object if no `:to` option is given. Default
  # is "current_#{user_model_name.downcase}".
  config.current_user_method = 'current_participant'
end

# Create application badges (uses https://github.com/norman/ambry)
Rails.application.reloader.to_prepare do
  if Merit::Badge.count == 0
    AicrowdBadge.where('level is not null').each do |badge|
      Merit::Badge.create!(id: badge.id, name: badge.name, description: badge.description, level: badge.level)
    end
  end
end
