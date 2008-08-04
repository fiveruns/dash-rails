require 'rubygems'
require 'echoe'

require File.dirname(__FILE__) << "/lib/fiveruns/dash/rails/version"

Echoe.new 'fiveruns_dash_rails' do |p|
  p.version = Fiveruns::Dash::Rails::Version::STRING
  p.author = "FiveRuns Development Team"
  p.email  = 'dev@fiveruns.com'
  p.project = 'fiveruns'
  p.summary = "FiveRuns Dash Rails recipes"
  p.url = "http://dash.fiveruns.com"
  p.include_rakefile = true
  p.runtime_dependencies = %w(fiveruns_dash)
  p.development_dependencies = %w(Shoulda)
  p.rcov_options = '--exclude gems --exclude version.rb --sort coverage --text-summary --html -o coverage'
end

task :coverage do
  system "open coverage/index.html" if PLATFORM['darwin']
end
