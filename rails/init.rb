require File.dirname(__FILE__) << "/../lib/fiveruns/dash/rails/startup"

if START_FIVERUNS_DASH_RAILS

  require 'fiveruns_dash_rails'
  Fiveruns::Dash.logger = RAILS_DEFAULT_LOGGER
  Fiveruns::Dash::Rails.load_recipes
  Fiveruns::Dash.configure do |config|
    config.add_recipe :ruby, :url => 'http://dash.fiveruns.com'
    config.add_recipe :rails, :url => 'http://dash.fiveruns.com'
  end

  # TODO: Only start-up when running the server
  require 'dispatcher'
  Dispatcher.to_prepare :check_configuration do
    Fiveruns::Dash::Rails.start
  end
end