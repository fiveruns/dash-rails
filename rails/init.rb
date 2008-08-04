gem 'fiveruns_dash'
require 'fiveruns/dash'

require 'fiveruns/dash/rails/version'

require 'dispatcher'

load_dash = false
loaded_gems = []

Dispatcher.to_prepare :check_configuration do
  load_dash = if Fiveruns::Dash.configuration.options[:app]
    true
  else
    # TODO: Add URL for help
    message =<<-EOM
FiveRuns Dash [Rails] (v#{Fiveruns::Dash::Rails::Version::STRING}) Application token missing
  ===
  In config/initializers/dash.rb or at the bottom of config/environment.rb, please add:
  
    Fiveruns::Dash.configure :app => 'YOUR-APP-TOKEN-HERE'
    
  See http://todo/path/to/help
  ===
    EOM
    RAILS_DEFAULT_LOGGER.warn(message.strip)
  end
end

Dispatcher.to_prepare :load_dash_recipes_from_plugins do
  if load_dash
    Dir["#{RAILS_ROOT}/vendor/plugins/*/dash/**/*.rb"].each do |file|
      require file
    end
  end
end

Dispatcher.to_prepare :load_dash_recipes_from_unpacked_gems do
  if load_dash
    Dir[File.join(RAILS_ROOT, 'vendor/gems/*')].each do |gem_path|
      name = File.basename(gem_path).sub(/-\d+-\d+-\d+#{Regexp.quote File::SEPARATOR}?$/, '')
      loaded_gems << name
      Dir[File.join(gem_path, 'dash/**/*.rb')].each do |file|
        require file
      end
    end
  end
end

Dispatcher.to_prepare :load_dash_recipes_from_system_gems do
  if load_dash
    config.gems.each do |gem|
      next if loaded_gems.include?(gem.name.to_s)
      spec = Gem.source_index.search(Gem::Dependency.new(gem.name, gem.requirement)).sort_by { |s| s.version }.last
      path = nil
      Gem.path.find do |gem_dir|
        location = File.join(gem_dir, 'gems', spec.full_name)
        path = location if File.directory?(location)
      end
      if path
        loaded_gems << gem.name.to_s
        Dir[File.join(path, 'dash/**/*.rb')].each do |file|
          require file
        end
      end
    end
  end
end