Fiveruns::Dash.register_recipe :actionpack, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :response_time, :method => 'ActionController::Base#perform_action'
  recipe.counter :requests, 'Requests', :incremented_by => 'ActionController::Base#perform_action'
end

Fiveruns::Dash.register_recipe :activerecord, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :activity, :method => 'ActiveRecord::ConnectionAdapters::AbstractAdapter#execute'
end

Fiveruns::Dash.register_recipe :rails, :url => 'http://dash.fiveruns.com' do |recipe|
  
  recipe.added do
    require File.dirname(__FILE__) << "/../lib/fiveruns/dash/rails"
    ActionController::Base.send(:include, Fiveruns::Dash::Rails::Context)
    if defined?(Mongrel)
      ObjectSpace.each_object do |obj|
        if obj.class == Mongrel::HttpServer
          Fiveruns::Dash::Rails.server = obj
        end
      end
    end
  end
  
  recipe.add_recipe :activerecord, :url => 'http://dash.fiveruns.com'
  # recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
  #   metric.find_context_with do |obj, *args|
  #     name = if obj.is_a?(ActiveRecord::Base)
  #       obj.class.name
  #     else
  #       obj.name
  #     end
  #     namespace = ['model', name]
  #     [
  #       nil,
  #       Array(Fiveruns::Dash::Rails::Context.context) + namespace
  #     ]
  #   end
  # end
  
  recipe.add_recipe :actionpack, :url => 'http://dash.fiveruns.com'
  recipe.modify :recipe_name => :actionpack, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      [
        nil,
        Fiveruns::Dash::Rails::Context.context
      ]
    end
  end
  
  recipe.add_exceptions_from 'ActionController::Base#perform_action_without_rescue' do |controller|
    session_data = nil
    begin
      session_data = controller.session.data.to_yaml
    rescue Exception => e
      Fiveruns::Dash.logger.warn "Could not retrieve session data for exception"
    end
    {:session => session_data, :headers => controller.request.headers.to_yaml, :params => controller.params.inspect}
  end
  
  recipe.absolute :queue_size do
    Fiveruns::Dash::Rails.queue_size || 0
  end
  
end