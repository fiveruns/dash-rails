START_FIVERUNS_DASH_RAILS = if ENV['START_FIVERUNS_DASH'] || File.basename($0) != 'irb'
  true
else
  module Fiveruns
    module Dash
      module Rails
        
        def self.configure(*args, &block)
          RAILS_DEFAULT_LOGGER.info "[FiveRuns Dash] Skipping configuration (`#{$0}' not supported for collection)"
        end
        
      end
    end
  end
  false
end

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