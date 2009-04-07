Fiveruns::Dash.register_recipe :rails, :url => 'http://dash.fiveruns.com' do |recipe|
  
  if defined?(ActiveRecord)
    recipe.add_recipe :activerecord, :url => 'http://dash.fiveruns.com',
                      :total_time => 'response_time'
    recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
      metric.find_context_with do |obj, *args|
        if Fiveruns::Dash::Context.context == []
          []
        else
          [[], Fiveruns::Dash::Context.context]
        end
      end
    end
  end

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
    info = {:name => "#{ex.class.name} in #{controller.class.name}##{controller.params[:action]}"}
    begin
      session_data = controller.request.session.instance_variable_get("@data")
      info[:session] = Fiveruns::Dash::Rails.clean_hash(session_data).to_fjson
    rescue Exception => e
      Fiveruns::Dash.logger.warn "Could not dump session data for exception: #{e.message}"
      nil
    end
    begin
      request_data = { :url => controller.request.url, :params => controller.params.inspect }
      info[:request] = Fiveruns::Dash::Rails.clean_hash(request_data).to_fjson
    rescue Exception => e 
      Fiveruns::Dash.logger.error "Could not dump request data for exception: #{e.message}"
      nil
    end
    begin
      header_data = controller.request.headers
      info[:headers] = Fiveruns::Dash::Rails.clean_hash(header_data).to_fjson
    rescue Exception => e 
      Fiveruns::Dash.logger.error "Could not dump header data for exception: #{e.message}"
      nil
    end
    info
  end
  
  # Same classes as the exception_notification plugin
  recipe.ignore_exceptions do |exception|
    Fiveruns::Dash::Rails::IGNORE_EXCEPTIONS.include?(exception.class)
  end

  recipe.added do
    
    if defined?(ActiveRecord)
      ActiveRecord::Base.send(:include, 
        Fiveruns::Dash::Rails::Context::ActiveRecord)
    end
    
    ActionController::Base.send(:include, 
      Fiveruns::Dash::Rails::Context::Action)
    
    if defined?(ActionView::Renderable)
      ActionView::Renderable.send(:include, 
        Fiveruns::Dash::Rails::Context::Template) 
    else
      if defined?(ActionView::Template)
        ActionView::Template.send(:include, 
          Fiveruns::Dash::Rails::Context::Template) 
      end
      
      if defined?(ActionView::InlineTemplate) && 
         Gem::Requirement.new('>= 2.2.0').
           satisfied_by?(Gem::Version.new(Rails.version))
        ActionView::InlineTemplate.send(:include, 
          Fiveruns::Dash::Rails::Context::Template) 
      end
      
      if defined?(ActionView::PartialTemplate)
        ActionView::PartialTemplate.send(:include, 
          Fiveruns::Dash::Rails::Context::Template) 
      end
    end

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

    if defined?(Passenger)
      # Passenger forks the Rails processes, which has the side effect of
      # killing our reporter thread.  We need to revive the thread.
      class ActionController::Base
        def perform_action_with_dash_startup(*args, &block)
          Fiveruns::Dash.session.reporter.revive!
          perform_action_without_dash_startup(*args, &block)
        end

        alias_method_chain :perform_action, :dash_startup
      end
    elsif defined?(PhusionPassenger)
      # Passenger 2.1+ has an event to handle this gracefully
      PhusionPassenger.on_event(:starting_worker_process) do
        Fiveruns::Dash.session.reporter.revive!
      end
    end
  end
  
end
