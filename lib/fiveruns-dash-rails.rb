require File.dirname(__FILE__) << "/fiveruns/dash/rails/startup"

if START_FIVERUNS_DASH_RAILS
  gem 'fiveruns-dash-ruby' # Put its path first
  require 'fiveruns/dash'
  begin
    require 'fiveruns/dash/activerecord'
  rescue LoadError
    abort "Missing the `activerecord' recipe. Please install the fiveruns-dash-activerecord gem"
  end
  require 'fiveruns/dash/rails'
  require 'fiveruns/dash/rails/template'
  require 'fiveruns/dash/rails/initializer'
  require 'fiveruns/dash/rails/context/action'
  require File.dirname(__FILE__) << "/../rails/init"  
end