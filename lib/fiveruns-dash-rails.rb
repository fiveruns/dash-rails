require File.dirname(__FILE__) << "/fiveruns/dash/rails/startup"

if START_FIVERUNS_DASH_RAILS
  gem 'fiveruns-dash-ruby' # Put its path first
  require 'fiveruns/dash'
  if defined?(ActiveRecord)
    begin
      require 'fiveruns/dash/activerecord'
    rescue LoadError
      abort "Missing the `activerecord' recipe. Please install the fiveruns-dash-activerecord gem"
    end
  end
  require 'fiveruns/dash/rails'
  require 'fiveruns/dash/rails/initializer'
  require 'fiveruns/dash/rails/context/action'
  if defined?(ActiveRecord)
    require 'fiveruns/dash/rails/context/active_record'
  end
  require 'fiveruns/dash/rails/context/template'
  require File.dirname(__FILE__) << "/../rails/init"  
end