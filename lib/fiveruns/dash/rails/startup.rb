# AKK: remove me in favor of inlining into init
START_FIVERUNS_DASH_RAILS = if ENV['START_FIVERUNS_DASH'] || File.basename($0) != 'irb'
  true
else
  module Fiveruns
    module Dash
      module Rails
        def self.start(*args, &block)
          RAILS_DEFAULT_LOGGER.info "[FiveRuns Dash] Skipping startup (`#{$0}' not supported)"
        end
        
        def self.configure(*args, &block)
          RAILS_DEFAULT_LOGGER.info "[FiveRuns Dash] Skipping configuration (`#{$0}' not supported for collection)"
        end
      end
    end
  end
  false
end
