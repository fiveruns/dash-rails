namespace :dash do
  desc "Verify FiveRuns Dash connectivity and configuration"
  task :test => :environment do
    begin
      verify('FiveRuns Dash loaded',
             'The FiveRuns Dash plugin has not been loaded.  Verify you are initializing Dash in config/initializers/dash.rb.') do
        defined? ::Fiveruns::Dash::Rails
      end
      verify('FiveRuns Dash configuration',
             "No application token was found for the #{Rails.env} environment.") do
        Fiveruns::Dash.configuration.options[:app]
      end
      verify('FiveRuns Dash session running', "FiveRuns Dash session is not active") do
        Fiveruns::Dash.session.reporter.alive?
      end
      verify('FiveRuns Dash network connectivity', "Error contacting the Dash service: ") do
        Fiveruns::Dash.session.reporter.ping
      end
    rescue ArgumentError
    end
  end
end

def verify(test, fail)
  $test_count = ($test_count || 0) + 1
  print "  #{$test_count}. #{test}..."
  begin
    result = yield
    if result
      puts "OK."
    else
      puts "FAIL!"
      puts e.message if e
      puts fail
      raise ArgumentError
    end
  rescue => e
    puts "FAIL!"
    puts fail
    raise e
  end
end
