module Fiveruns::Dash::Rails::Context
  
  module Action

    def self.included(base)
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
    
  end

end