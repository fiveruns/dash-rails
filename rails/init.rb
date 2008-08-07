gem 'fiveruns_dash'
require 'fiveruns/dash'

require 'fiveruns/dash/rails'

Fiveruns::Dash::Rails.load_recipes

Dispatcher.to_prepare :check_configuration do
  load_dash = if Fiveruns::Dash.configuration.options[:app]
    true
  else
    # TODO: Add URL for help
    message =<<-EOM
FiveRuns Dash [Rails] (v#{Fiveruns::Dash::Rails::Version::STRING}) Application token missing
  ===
  In config/initializers/dash.rb or at the bottom of config/environment.rb, please add:
  
    Fiveruns::Dash.configure :app => 'YOUR-APP-TOKEN-HERE'
    
  See http://todo/path/to/help
  ===
    EOM
    RAILS_DEFAULT_LOGGER.warn(message.strip)
  end
end