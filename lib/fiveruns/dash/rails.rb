require File.dirname(__FILE__) << "/rails/startup"

if START_FIVERUNS_DASH_RAILS
  
  module Fiveruns
    module Dash
    
      module Rails
        
        version_file = File.expand_path(File.dirname(__FILE__) << "/../../../version.yml")
        version = YAML.load(File.read(version_file))
        VERSION = [
          version[:major],
          version[:minor],
          version[:patch]
        ].map(&:to_s).join('.')
        
        IGNORE_EXCEPTIONS = [
          ::ActionController::RoutingError,
          ::ActionController::UnknownController,
          ::ActionController::UnknownAction
        ]
        if defined?(::ActiveRecord)
          IGNORE_EXCEPTIONS << ::ActiveRecord::RecordNotFound
        end
      
        class << self
          attr_accessor :server
        end
        
        def self.clean_hash(obj = {})
          (obj || {}).keys.inject({}) do |all, key|
            val = obj[key]
            if val.is_a?(Hash)
              val = clean_hash(val)
            end
            all[key.to_s] = val
            all
          end
        end
      
        def self.queue_size
          return 0 unless server_type
          case server_type
          when :mongrel
            server.workers.list.length
          else
            0 # Skip
          end
        end
      
        def self.server_type
          return @server_type if defined?(@server_type)
          @server_type = if server          
            case server.class.to_s
            when /Mongrel/
              :mongrel
            else
              ::Fiveruns::Dash.logger.warn "Unrecognized app server type: #{server.class}, not collecting queue size"
              false
            end
          else
            ::Fiveruns::Dash.logger.warn "Could not find app server, not collecting queue size"
            nil
          end
        end
                    
        def self.load_recipes
          Dir[File.dirname(__FILE__) << "/recipes/**/*.rb"].each do |file|
            require file
          end
        end
      
        def self.start(tokens = {}, &block)
          return if Fiveruns::Dash.application.session.reporter.started?
          ::Rails::Initializer.send(:include, Fiveruns::Dash::Rails::Initializer)
          store_dash_start_block do 
            configure(tokens, &block) unless tokens.empty?
            if Fiveruns::Dash.application.token
              Fiveruns::Dash.application.session.start 
            else
              log_error unless env == 'development'
            end
          end
        end
        
        def self.store_dash_start_block(&block)
          @dash_start_block = block
        end
        
        def self.dash_start_block
          @dash_start_block ||= lambda {}
        end
        
        
        def self.configure(tokens = {}, &block)
          tokens.each do |environment, token|
            if environment.to_s == self.env
              Fiveruns::Dash.configure({:app => token}, &block)
              break
            end
          end
        end
        
        def self.log_error
          # TODO: Add URL for help
          message =<<-EOM
  FiveRuns Dash [Rails] (v#{VERSION}) Application token missing
    ===
    In config/initializers/dash.rb please add:

      Fiveruns::Dash::Rails.start :#{env} => '#{env.upcase}-APP-TOKEN'

    You can also set app tokens for other environments (eg, staging), at the same time.
    See http://support.fiveruns.com/faqs/dash/rails for more information
    ===
          EOM
          RAILS_DEFAULT_LOGGER.warn(message.strip)
        end
        
        def self.env
          ::Rails.env # >= Rails 2.1
        rescue
          ENV['RAILS_ENV'] # <= Rails 2.0 
        end
        
        def self.verify
          puts ""
          puts "FiveRuns Dash installation verification"
          puts "======================================="
          puts ""
          Fiveruns::Dash.logger = Logger.new(STDOUT)
          Fiveruns::Dash.logger.level = Logger::WARN
          test('FiveRuns Dash loaded',
               'The FiveRuns Dash plugin has not been loaded.  Verify you are initializing Dash in config/initializers/dash.rb.') do
            defined? ::Fiveruns::Dash::Rails
          end
          test('FiveRuns Dash configuration',
               "No application token was found for the #{Rails.env} environment.") do
            Fiveruns::Dash.configuration.options[:app]
          end
          test('FiveRuns Dash session running', "FiveRuns Dash session is not active") do
            Fiveruns::Dash.session.reporter.alive?
          end
          test('JSON compatibility', "Looks like you've run afoul of an ActiveSupport and JSON incompatibility. The easiest way to fix this is to load json from a gem, instead of unpacking it. See http://support.fiveruns.com/faqs/dash/json-compatibility for details.") do
            begin
              info = Fiveruns::Dash.session.info
              payload = Fiveruns::Dash::InfoPayload.new(info, Time.now)
              result = payload.to_fjson
            rescue ArgumentError
              false
            end
          end
          test('FiveRuns Dash network connectivity') do
            Fiveruns::Dash.session.reporter.ping
          end
          puts ""
          puts "All appears normal.  If you are experiencing a problem, please email support@fiveruns.com with details about the problem and your environment."
          puts ""
        rescue ArgumentError
        end
        
        def self.test(test, fail=nil)
          $test_count = ($test_count || 0) + 1
          print "  #{$test_count}. #{test}..."
          begin
            result = yield
            if result
              puts "OK." if fail
            else
              if fail
                puts "FAIL!"
                puts fail
              end
              raise ArgumentError
            end
          rescue ArgumentError => ex
            raise ex
          rescue => e
            puts "FAIL!"
            puts fail
            raise e
          end
        end
        
      end 
      
    end
    
  end

end