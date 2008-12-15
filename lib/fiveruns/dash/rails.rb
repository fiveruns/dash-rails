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
                    
        def self.load_recipes
          Dir[File.dirname(__FILE__) << "/../../../dash/**/*.rb"].each do |file|
            require file
          end
        end
      
        def self.start(tokens = {}, &block)
          return if Fiveruns::Dash.session.reporter.started?  
          configure(tokens, &block) unless tokens.empty?
          if Fiveruns::Dash.configuration.ready?
            RAILS_DEFAULT_LOGGER.info "Starting Dash"
            Fiveruns::Dash.session.start 
          else
            log_error unless env == 'development'
          end
        end
        
        def self.configure(tokens = {}, &block)
          tokens.each do |environment, token|
            if environment.to_s == self.env
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

      Fiveruns::Dash::Rails.configure :#{env} => 'YOUR-#{env.upcase}-ENV-APP-TOKEN-HERE'

    You can also set app tokens for other environments (eg, staging), at the same time.
    See http://todo/path/to/help for more information
    ===
          EOM
          RAILS_DEFAULT_LOGGER.warn(message.strip)
        end
        
        def self.contextualize_action_pack(metric)
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
        
        def self.contextualize_active_record(metric)
          metric.find_context_with do |obj, *args|
            [[], Fiveruns::Dash::Context.context]
          end
        end

        def self.env
          ::Rails.env # >= Rails 2.1
        rescue
          ENV['RAILS_ENV'] # <= Rails 2.0 
        end
        
        module ActionContext
      
          def self.included(base)
            base.send(:include, InstanceMethods)
            base.alias_method_chain :perform_action, :fiveruns_dash_context
            base.extend(ClassMethods)
            (class << base; self; end).alias_method_chain :process, :fiveruns_dash_tracing
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
              Fiveruns::Dash::Context.set ['action', %(#{self.class.name}##{action_name})]
              perform_action_without_fiveruns_dash_context(*args, &block)
            end
        
          end
      
        end
        
      end 
      
    end
    
  end

end