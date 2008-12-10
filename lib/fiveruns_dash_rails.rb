require File.dirname(__FILE__) << "/fiveruns/dash/rails/startup"

if START_FIVERUNS_DASH_RAILS
  gem 'fiveruns_dash' # Put its path first
  require 'fiveruns/dash'
  require 'fiveruns/dash/rails'
  require 'fiveruns/dash/template_context'
  require 'fiveruns/dash/active_record_context'
end
