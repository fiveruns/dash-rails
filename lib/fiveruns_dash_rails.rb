require File.dirname(__FILE__) << "/fiveruns/dash/rails/startup"

if START_FIVERUNS_DASH_RAILS
  gem 'fiveruns_dash' # Put its path first
  require 'fiveruns/dash'
  require 'fiveruns/dash/rails'
end