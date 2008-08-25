require File.dirname(__FILE__) << "/rails/version"

module Fiveruns
  module Dash
    
    module Rails
      
      cattr_accessor :server
      
      def self.queue_size
        return nil unless server_type
        case server_type
        when :mongrel
          server.workers.list.size
        else
          # Skip
        end
      end
      
      def self.server_type
        return @server_type if defined?(@server_type)
        @server_type = if server          
          case server.class.to_s
          when /Mongrel/
            :mongrel
          else
            ::Fiveruns::Dash.log :warn, "Unrecognized app server type: #{server.class}, not collecting queue size"
            false
          end
        else
          ::Fiveruns::Dash.log :warn, "Could not find app server, not collecting queue size"
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
      
      module Context
      
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.alias_method_chain :perform_action, :fiveruns_dash_context
        end
        
        def self.set(value)
          ::Fiveruns::Dash.sync { @context = value }
        end
        
        def self.reset
          ::Fiveruns::Dash.sync { @context = nil }
        end
      
        class << self
          attr_reader :context
        end
      
        module InstanceMethods
          def perform_action_with_fiveruns_dash_context(*args, &block)
            action_name = (request.parameters['action'] || 'index').to_s
            Fiveruns::Dash::Rails::Context.set ['action', %(#{self.class.name}##{action_name})]
            perform_action_without_fiveruns_dash_context(*args, &block)
          end
        end
        
      end
      
    end
    
  end
end
      