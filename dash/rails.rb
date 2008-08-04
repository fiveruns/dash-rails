Fiveruns::Dash.register_recipe :rails do |recipe|
  
  recipe.included do
    require File.dirname(__FILE__) << "/../lib/fiveruns/dash/rails"
    ActionController::Base.send(:include, Fiveruns::Dash::Rails::Context)
  end
  
  # TODO
  
end