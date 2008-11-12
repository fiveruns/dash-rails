# ActionPack ##################################################################
Fiveruns::Dash.register_recipe :actionpack, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :response_time, :method => 'ActionController::Base#perform_action'
  recipe.counter :requests, 'Requests', :incremented_by => 'ActionController::Base#perform_action'
  
  targets = []
  targets << 'ActionView::Template#render' if defined?(ActionView::Template)
  targets << 'ActionView::PartialTemplate#render' if defined?(ActionView::PartialTemplate)
  if !targets.empty?
    recipe.time :render_time, :method => targets
  else
    Fiveruns::Dash.logger.warn 'Collection of "render_time" unsupported for this version of Rails'
  end
end

# ActiveRecord ################################################################
Fiveruns::Dash.register_recipe :activerecord, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :activity, :methods => %w(ActiveRecord::Base.find_by_sql ActiveRecord::Base.calculate)
end

# Rails #######################################################################
Fiveruns::Dash.register_recipe :rails, :url => 'http://dash.fiveruns.com' do |recipe|  
  recipe.added do
    require File.dirname(__FILE__) << "/../lib/fiveruns/dash/rails"
    ActionController::Base.send(:include, 
                                Fiveruns::Dash::Rails::ActionContext)
    ActionView::Template.send(:include, 
                                Fiveruns::Dash::Rails::TemplateContext) if defined?(ActionView::Template)
    ActionView::PartialTemplate.send(:include, 
                                Fiveruns::Dash::Rails::TemplateContext) if defined?(ActionView::PartialTemplate)
    
    begin
      if defined?(Mongrel)
        ActiveSupport::Deprecation.silence do
          ObjectSpace.each_object do |obj|
            if obj.class == Mongrel::HttpServer
              Fiveruns::Dash::Rails.server = obj
            end
          end
        end
      end
    rescue Exception => e
      if RUBY_PLATFORM =~ /java/ && e.message =~ /ObjectSpace/
        puts "Unable to access ObjectSpace: #{e.message}"
      else
        raise e
      end
    end
  end
  
  recipe.add_recipe :activerecord, :url => 'http://dash.fiveruns.com'
  recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      namespace = ['model', obj.name]
      [nil, Array(Fiveruns::Dash::Rails::Context.context) + namespace]
    end
  end
  
  recipe.add_recipe :actionpack, :url => 'http://dash.fiveruns.com'
  recipe.modify :recipe_name => :actionpack, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    Fiveruns::Dash::Rails.contextualize_action_pack(metric)
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