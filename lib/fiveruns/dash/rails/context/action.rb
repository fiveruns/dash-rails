module Fiveruns::Dash::Rails::Context
  
  module Action

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