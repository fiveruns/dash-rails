# * Average Action Response Time: per 1 min interval, most important metric to me?
# ** Captured at 'response_time' metric by 'actionpack' recipe
# * Action Requests?: per 1min interval, has to accompany 1 above?
# ** Captured as 'requests' metric by 'actionpack' recipe
# * ActiveRecord Activity Indicator: ?percent per 1 min interval, aggregate metric, tbd?
# ** Captured as 'activity' metric by 'activerecord' recipe
# * Includes slowest, most frequently called actions/models information
# ** This feature is provided by the 'response_time' (actionpack) and 'activity' (activerecord)
#    metrics and the metric store structure; a function of how the data is sliced
# * Active Rails processes: unique PIDs reporting per interval, smoothed out for restarts?
# ** These are captured as the number of 'Process' records
# * Aggregated Rails Process CPU Usage: ?percent per 1 min interval?
# ** Captured as 'cpu' metric by 'ruby' recipe
# * Aggregated Rails Memory Usage?: percent per 1 min interval?
# ** Captured as 'pmem' remtric by 'ruby' recipe
# ** Also capturing as bytes in 'rss' metric by 'ruby' recipe
# * Mongrel Queue Size?: If available?, alternative metric for thin?


Fiveruns::Dash.register_recipe :actionpack, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :response_time, :method => 'ActionController::Base#perform_action'
  recipe.counter :requests, 'Requests', :incremented_by => 'ActionController::Base#perform_action'
end

Fiveruns::Dash.register_recipe :activerecord, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :activity, :method => 'ActionController::Base.execute'
end

Fiveruns::Dash.register_recipe :rails, :url => 'http://dash.fiveruns.com' do |recipe|
  
  recipe.added do
    require File.dirname(__FILE__) << "/../lib/fiveruns/dash/rails"
    ActionController::Base.send(:include, Fiveruns::Dash::Rails::Context)
    ObjectSpace.each_object do |obj|
      if obj.class == Mongrel::HttpServer
        Fiveruns::Dash::Rails.server = obj
      end
    end
  end
  
  recipe.add_recipe :activerecord, :url => 'http://dash.fiveruns.com'
  recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      name = if obj.is_a?(ActiveRecord::Base)
        obj.class.name
      else
        obj.name
      end
      namespace = ['model', name]
      [
        nil,
        Array(Fiveruns::Dash::Rails::Context.context) + namespace
      ]
    end
  end
  
  recipe.add_recipe :actionpack, :url => 'http://dash.fiveruns.com'
  recipe.modify :recipe_name => :actionpack, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      Fiveruns::Dash::Rails::Context.context
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
    Fiveruns::Dash::Rails.queue_size
  end
  
end