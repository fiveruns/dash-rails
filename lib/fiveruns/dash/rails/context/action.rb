module Fiveruns::Dash::Rails::Context
  
  module Action

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.alias_method_chain :perform_action, :fiveruns_dash_context
    end

    module InstanceMethods 
         
      def perform_action_with_fiveruns_dash_context(*args, &block)
        action_name = (request.parameters['action'] || 'index').to_s
        Fiveruns::Dash::Write::Context.set ['action', %(#{self.class.name}##{action_name})]
        perform_action_without_fiveruns_dash_context(*args, &block)
      end

    end
    
  end

end