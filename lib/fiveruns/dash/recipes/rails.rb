begin
  require 'fiveruns/dash/recipes/activerecord'
rescue LoadError
  abort "Missing the `activerecord' recipe. Please install the fiveruns-dash-activerecord gem"
end

module Fiveruns::Dash::Rails::Hash
  
  def self.clean(extended_hash = {})
    (extended_hash || {}).keys.inject({}) do |all, key|
      val = extended_hash[key]
      if val.kind_of? Hash
        val = clean(val)
      end
      all[key.to_s] = val
      all
    end
  end
  
end

module Fiveruns::Dash::ActiveRecordContext
  CLASS_METHODS = %w(find find_by_sql calculate create create! update_all destroy destroy_all delete delete_all)
  INSTANCE_METHODS = %w(update save save! destroy)

  def self.included(base)
    class << base
      CLASS_METHODS.each do |meth|
        head = meth
        tail = ''
        head, tail = meth[0..(meth.length-2)], meth[-1..-1] if %w(? !).include? meth[-1..-1]
        self.class_eval <<-EOM
          def #{head}_with_dash_context#{tail}(*args, &block)
            Fiveruns::Dash::ActiveRecordContext.with_model_context(self.name) do
              #{head}_without_dash_context#{tail}(*args, &block)
            end
          end
        EOM
        alias_method_chain(meth.to_sym, :dash_context)
      end
    end

    INSTANCE_METHODS.each do |meth|
      head = meth
      tail = ''
      head, tail = meth[0..meth.length-2], meth[-1..-1] if %w(? !).include? meth[-1..-1]
      base.class_eval <<-EOM
        def #{head}_with_dash_context#{tail}(*args, &block)
          Fiveruns::Dash::ActiveRecordContext.with_model_context(self.class.name) do
            #{head}_without_dash_context#{tail}(*args, &block)
          end
        end
      EOM
      base.alias_method_chain(meth.to_sym, :dash_context)
    end
  end

  def self.with_model_context(model_name)
    ctx = Fiveruns::Dash::Context.context
    # don't change context if model context has already been set.
    return yield if ctx.size > 0 && ctx[-2] == 'model' && ctx[-1] == model_name

    original_context = Fiveruns::Dash::Context.context.dup
    begin
      if ctx[-2] == 'model'
        # Some models will internally load other models.
        Fiveruns::Dash::Context.context.pop
        Fiveruns::Dash::Context.context << model_name
      else
        Fiveruns::Dash::Context.context << 'model'
        Fiveruns::Dash::Context.context << model_name
      end
      return yield
    ensure
      Fiveruns::Dash::Context.set original_context
    end
  end
  
  def self.all_methods
    CLASS_METHODS.map { |m| "ActiveRecord::Base.#{m}" } + INSTANCE_METHODS.map { |m| "ActiveRecord::Base##{m}"}
  end
  
end


# ActionPack ##################################################################
Fiveruns::Dash.register_recipe :actionpack, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.time :response_time, :method => 'ActionController::Base#perform_action', :mark => true
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
  recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      if Fiveruns::Dash::Context.context == []
        []
      else
        [[], Fiveruns::Dash::Context.context]
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
      info[:session] = Fiveruns::Dash::Rails::Hash.clean(session_data).to_json
    rescue Exception => e
      Fiveruns::Dash.logger.warn "Could not dump session data for exception: #{e.message}"
      nil
    end
    begin
      request_data = { :url => controller.request.url, :params => controller.params.inspect }
      info[:request] = Fiveruns::Dash::Rails::Hash.clean(request_data).to_json
    rescue Exception => e 
      Fiveruns::Dash.logger.error "Could not dump request data for exception: #{e.message}"
      nil
    end
    begin
      header_data = controller.request.headers
      info[:headers] = Fiveruns::Dash::Rails::Hash.clean(header_data).to_json
    rescue Exception => e 
      Fiveruns::Dash.logger.error "Could not dump header data for exception: #{e.message}"
      nil
    end
    info
  end
  
  # Same classes as the exception_notification plugin
  IGNORE = [ActiveRecord::RecordNotFound, ActionController::RoutingError, ActionController::UnknownController, ActionController::UnknownAction]

  recipe.ignore_exceptions do |exc|
    IGNORE.include? exc.class
  end

  recipe.added do
    ActiveRecord::Base.send(:include, Fiveruns::Dash::ActiveRecordContext)
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
