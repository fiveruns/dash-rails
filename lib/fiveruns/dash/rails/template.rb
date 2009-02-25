module Fiveruns::Dash::Rails::Template
  
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
  
end