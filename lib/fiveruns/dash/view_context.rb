
module Fiveruns::Dash::Rails::ViewContext
  
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
  
  def self.sanitize_view_path(path)
    # In the future, we may want to remove the RAILS_ROOT
    # namespace = ['view', Fiveruns::Dash::Rails::ViewContext.context.last + self.path.sub(/^#{Regexp.quote RAILS_ROOT}\//, '')]
    path
  end
  
  module InstanceMethods
    
    def render_with_fiveruns_dash_context(*args, &block)
      original_context = Fiveruns::Dash::Rails::ViewContext.context.dup
      
      template = Fiveruns::Dash::Rails::ViewContext.sanitize_view_path(path)
      Fiveruns::Dash::Rails::ViewContext.context << 'view'
      Fiveruns::Dash::Rails::ViewContext.context << template
      
      render_without_fiveruns_dash_context(*args, &block)
      
      Fiveruns::Dash::Rails::ViewContext.set original_context
    end
    
  end
  
end
