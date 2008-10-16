require File.dirname(__FILE__) << "/rails/version"
require File.dirname(__FILE__) << "/rails/startup"

if START_FIVERUNS_DASH_RAILS
  
  module Fiveruns
    module Dash
    
      module Rails
      
        class << self
          attr_accessor :server
        end
      
        def self.queue_size
          return 0 unless server_type
          case server_type
          when :mongrel
            server.workers.list.length
          else
            0 # Skip
          end
        end
      
        def self.server_type
          return @server_type if defined?(@server_type)
          @server_type = if server          
            case server.class.to_s
            when /Mongrel/
              :mongrel
            else
              ::Fiveruns::Dash.logger.warn "Unrecognized app server type: #{server.class}, not collecting queue size"
              false
            end
          else
            ::Fiveruns::Dash.logger.warn "Could not find app server, not collecting queue size"
            nil
          end
        end
                    
        # Just in case the plugin isn't being used a gem,
        # and the packaged recipes aren't loaded automatically
        def self.load_recipes
          Dir[File.dirname(__FILE__) << "/../../../dash/**/*.rb"].each do |file|
            require file
          end
        end
      
        def self.start
          return if Fiveruns::Dash.session.reporter.started?
          if Fiveruns::Dash.configuration.ready?
            RAILS_DEFAULT_LOGGER.info "Starting Dash"
            Fiveruns::Dash.session.start 
          else
            log_error unless ::Rails.env == 'development'
          end
        end
      
        def self.configure(tokens = {}, &block)
          tokens.each do |environment, token|
            if environment.to_s == ::Rails.env
              Fiveruns::Dash.configure({:app => token}, &block)
              break
            end
          end
        end
      
        def self.log_error
          # TODO: Add URL for help
          message =<<-EOM
  FiveRuns Dash [Rails] (v#{Version::STRING}) Application token missing
    ===
    In config/initializers/dash.rb or at the bottom of config/environment.rb, please add:

      Fiveruns::Dash::Rails.configure :#{::Rails.env} => 'YOUR-#{::Rails.env.upcase}-ENV-APP-TOKEN-HERE'

    You can also set app tokens for other environments (eg, staging), at the same time.
    See http://todo/path/to/help for more information
    ===
          EOM
          RAILS_DEFAULT_LOGGER.warn(message.strip)
        end
      
      def self.contextualize_action_pack(metric)
        if metric.name.to_s == 'render_time'
          metric.find_context_with do |obj, *args|
            # namespace = ['view', obj.path.sub(/^#{Regexp.quote RAILS_ROOT}\//, '')]
            # [nil, Fiveruns::Dash::Rails::ViewContext.context + namespace]
            Fiveruns::Dash::Rails::ViewContext.context
          end
        else
          metric.find_context_with do |obj, *args|
            [nil, Fiveruns::Dash::Rails::ActionContext.context]
          end
        end
      end
      
      module ActionContext
      
          def self.included(base)
            base.send(:include, InstanceMethods)
            base.alias_method_chain :perform_action, :fiveruns_dash_context
            base.extend(ClassMethods)
            (class << base; self; end).alias_method_chain :process, :fiveruns_dash_tracing
          end
        
          def self.set(value)
            ::Fiveruns::Dash.sync { @context = value }
          end
        
          def self.reset
            ::Fiveruns::Dash.sync { @context = [] }
          end
      
          def self.context
            @context ||= []
          end
        
          module ClassMethods
          
            def process_with_fiveruns_dash_tracing(*args, &block)
              operation = lambda { process_without_fiveruns_dash_tracing(*args, &block) }
              params = args.first.parameters
              # TODO/FIXME: For now, we simply look for a 'trace' parameter to select requests to trace; in the
              #             future, we need a more advanced sampling mechanism (some operation in a recipe a
              #             request must pass, or selection criteria returned in a response from the service)
              trace_context = ['action', "#{params['controller'].camelize}Controller##{params['action']}"]
              if ::Fiveruns::Dash.trace_contexts.include?(trace_context)
                ::Fiveruns::Dash.session.trace(trace_context) do
                  operation.call
                end
              else
                operation.call
              end
            end
          
          end
      
        module InstanceMethods 
                    
          def perform_action_with_fiveruns_dash_context(*args, &block)
            action_name = (request.parameters['action'] || 'index').to_s
            Fiveruns::Dash::Rails::ActionContext.set ['action', %(#{self.class.name}##{action_name})]
            perform_action_without_fiveruns_dash_context(*args, &block)
          end
        
        end
      
      end
      
      module ViewContext
        
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.alias_method_chain(:render, :fiveruns_dash_context)
        end
        
        # Cargo culted from ActionContext
        def self.set(value)
          ::Fiveruns::Dash.sync { @context = value }
        end
        
        # Cargo culted from ActionContext
        def self.reset
          ::Fiveruns::Dash.sync { @context = [] }
        end
        
        # Cargo culted from ActionContext
        def self.context
          @context ||= []
        end
        
        module InstanceMethods
          
          def render_with_fiveruns_dash_context(*args, &block)
            original_context = Fiveruns::Dash::Rails::ViewContext.context
            puts "original: #{original_context.inspect}"
            
            # namespace = ['view', Fiveruns::Dash::Rails::ViewContext.context.last + self.path.sub(/^#{Regexp.quote RAILS_ROOT}\//, '')]
            namespace = Fiveruns::Dash::Rails::ViewContext.context << ['view', path]
            
            Fiveruns::Dash::Rails::ViewContext.set namespace.flatten
            
            puts "STOOEY: #{Fiveruns::Dash::Rails::ViewContext.context.inspect}"
            
            render_without_fiveruns_dash_context(*args, &block)
            
            Fiveruns::Dash::Rails::ViewContext.set original_context
          end
          
        end
        
      end
      
    end
    
  end
  
end
