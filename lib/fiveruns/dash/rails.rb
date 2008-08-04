module Fiveruns
  module Dash
    
    module Rails
      
      module Context
      
        def self.included(base)
          base.send(:include, InstanceMethods)
          base.alias_method_chain :perform_action, :fiveruns_dash_context
        end
      
        def self.controller_context
          if context
            context[0, 2]
          end
        end
      
        def self.action_context
          if context
            context[2, 2]
          end
        end
        
        def self.set(value)
          @context = value
          if block_given?
            yield
            reset
          end
        end
        
        def self.reset
          @context = nil
        end
      
        class << self
          attr_reader :context
        end
      
        module InstanceMethods
          def perform_action_with_fiveruns_dash_context(*args, &block)
            action_name = (request.parameters['action'] || 'index').to_s
            Fiveruns::Dash::Rails::Context.set [:controller, controller_name, :action, action_name] do
              perform_action_without_fiveruns_dash_context(*args, &block)
            end
          end
        end
        
      end
      
    end
    
  end
end
      