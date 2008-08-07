gem 'fiveruns_dash' # Put its path first
require 'fiveruns/dash'
Fiveruns::Dash.logger = RAILS_DEFAULT_LOGGER

require 'fiveruns/dash/rails'
Fiveruns::Dash::Rails.load_recipes

require 'dispatcher'
Dispatcher.to_prepare :check_configuration do
  Fiveruns::Dash::Rails.start
end