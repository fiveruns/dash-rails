
module Fiveruns::Dash::Rails::TemplateContext
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.alias_method_chain(:render, :fiveruns_dash_context)
  end
  
  RAILS_ROOT_RE = /\A#{Regexp.quote RAILS_ROOT}/

  GEM_REs = Gem.path.map do |path|
    /\A#{Regexp.quote path}\/gems/
  end
  
  def self.sanitize_view_path(path)
    path = if path[0..0] == '/'
      if path =~ RAILS_ROOT_RE
        trimmed = path.sub(RAILS_ROOT_RE, 'RAILS_ROOT')
        trimmed
      elsif (re = GEM_REs.find { |re| path =~ re })
        trimmed = path.sub(re, 'GEMS')
      else
        path
      end
    else
      path
    end
    # Remove extensions, if any
    path.sub(/\.[^\/\\]*$/, '')
  end

  module InstanceMethods
    
    def render_with_fiveruns_dash_context(*args, &block)
      original_context = Fiveruns::Dash::Rails::Context.context.dup
      
      begin
        template = Fiveruns::Dash::Rails::TemplateContext.sanitize_view_path(path)
        Fiveruns::Dash::Rails::Context.context << 'view'
        Fiveruns::Dash::Rails::Context.context << template
        result = render_without_fiveruns_dash_context(*args, &block)
      ensure
        Fiveruns::Dash::Rails::Context.set original_context
      end
      
      result
    end
    
  end
  
end
