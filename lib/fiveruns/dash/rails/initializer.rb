module Fiveruns::Dash::Rails::Initializer
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.alias_method_chain :prepare_dispatcher, :dash
  end
  
  module InstanceMethods
    
    def prepare_dispatcher_with_dash
      prepare_dispatcher_without_dash
      Fiveruns::Dash::Rails.dash_start_block.call
    end
    
  end
  
end