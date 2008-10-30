
module Fiveruns::Dash::Rails::TemplateContext
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.alias_method_chain(:render, :fiveruns_dash_context)
  end
  
  def self.sanitize_view_path(path)
    # In the future, we may want to remove the RAILS_ROOT
    # namespace = ['view', Fiveruns::Dash::Rails::Context.context.last + self.path.sub(/^#{Regexp.quote RAILS_ROOT}\//, '')]
    path
  end
  
  module InstanceMethods
    
    def render_with_fiveruns_dash_context(*args, &block)
      original_context = Fiveruns::Dash::Rails::Context.context.dup
      
      template = Fiveruns::Dash::Rails::TemplateContext.sanitize_view_path(path)
      Fiveruns::Dash::Rails::Context.context << 'view'
      Fiveruns::Dash::Rails::Context.context << template
      
      result = render_without_fiveruns_dash_context(*args, &block)
      
      Fiveruns::Dash::Rails::Context.set original_context
      return result
    end
    
  end
  
end
