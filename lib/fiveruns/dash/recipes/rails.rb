module Fiveruns::Dash::Rails::Hash
  
  def self.clean(extended_hash)
    extended_hash.keys.inject({}) do |all, key|
      val = extended_hash[key]
      if val.kind_of? Hash
        val = clean(val)
      end
      all[key.to_s] = val
      all
    end
  end
  
end

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

# Rails #######################################################################
Fiveruns::Dash.register_recipe :rails, :url => 'http://dash.fiveruns.com' do |recipe|  
  recipe.add_recipe :activerecord, :url => 'http://dash.fiveruns.com'

  recipe.add_recipe :actionpack, :url => 'http://dash.fiveruns.com'
  recipe.modify :recipe_name => :actionpack, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    if metric.name.to_s == 'render_time'
      metric.find_context_with do |obj, *args|
        Fiveruns::Dash::Context.context
      end
    else
      metric.find_context_with do |obj, *args|
        [[], Fiveruns::Dash::Context.context]
      end
    end
  end

  recipe.add_exceptions_from 'ActionController::Base#perform_action_without_rescue' do |ex, controller|
    session_data = nil
    begin
      session_data = controller.request.session.instance_variable_get("@data")
    rescue Exception => e
      Fiveruns::Dash.logger.warn "Could not retrieve session data for exception: #{e.message}"
    end
    {
      :name => "#{ex.class.name} in #{controller.class.name}##{controller.params[:action]}", # Override the standard name 
      :session => Fiveruns::Dash::Rails::Hash.clean(session_data).to_json,
      :headers => Fiveruns::Dash::Rails::Hash.clean(controller.request.headers).to_json,
      :request => { :url => controller.request.url, :params => controller.params.inspect }.to_json,
    }
  end
  
  recipe.added do
    ActionController::Base.send(:include, Fiveruns::Dash::Rails::ActionContext)
    ActionView::Template.send(:include, Fiveruns::Dash::Rails::TemplateContext) if defined?(ActionView::Template)
    ActionView::InlineTemplate.send(:include, Fiveruns::Dash::Rails::TemplateContext) if defined?(ActionView::InlineTemplate)
    ActionView::PartialTemplate.send(:include, Fiveruns::Dash::Rails::TemplateContext) if defined?(ActionView::PartialTemplate)

    begin
      if defined?(Mongrel)
        ActiveSupport::Deprecation.silence do
          # Unfortunately there is no known way to get direct access
          # to the Mongrel singleton.  Wade through the Ruby heap to
          # find it.
          ObjectSpace.each_object do |obj|
            if obj.class == Mongrel::HttpServer
              Fiveruns::Dash::Rails.server = obj
            end
          end
        end
      end
    rescue Exception => e
      if RUBY_PLATFORM =~ /java/ && e.message =~ /ObjectSpace/
        Fiveruns::Dash.logger.info "Cannot find Mongrel: #{e.message}"
      else
        raise e
      end
    end

    # Passenger forks the Rails processes, which has the side effect of
    # killing our reporter thread.  We need to revive the thread.
    class ActionController::Base
      def perform_action_with_dash_startup(*args, &block)
        Fiveruns::Dash.session.reporter.revive!
        perform_action_without_dash_startup(*args, &block)
      end

      alias_method_chain :perform_action, :dash_startup
    end
  end
  
  recipe.absolute :queue_size do
    Fiveruns::Dash::Rails.queue_size || 0
  end
end
