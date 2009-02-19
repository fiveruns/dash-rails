require 'rubygems'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.verbose = true
  t.test_files = FileList['test/*_test.rb']
  t.libs  << 'lib'
end

task :default => :test

begin 
  require 'jeweler' 

  Jeweler::Tasks.new do |s| 
    s.name = "dash-rails" 
    s.rubyforge_project = 'fiveruns'
    s.summary = "FiveRuns Dash recipe for Ruby on Rails" 
    s.email = "dev@fiveruns.com" 
    s.homepage = "http://github.com/fiveruns/dash-rails" 
    s.description = "Provides an API to send metrics from Rails applications to the FiveRuns Dash service" 
    s.authors = ["FiveRuns Development Team"] 
    s.files = FileList['README.rdoc', 'Rakefile', 'VERSION.yml', 'init.rb', "{lib,rails,test}/**/*", ] 
    s.add_dependency 'fiveruns-dash-ruby', '>= 0.8.1' 
    s.add_dependency 'fiveruns-dash-activerecord', '>= 0.8.1'
  end 
rescue LoadError 
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com" 
end

task :coverage do
  rm_f "coverage"
  rm_f "coverage.data"
  rcov = "rcov --exclude gems --exclude version.rb --sort coverage --text-summary --html -o coverage"
  system("#{rcov} test/*_test.rb")
  if ccout = ENV['CC_BUILD_ARTIFACTS']
    FileUtils.rm_rf '#{ccout}/coverage'
    FileUtils.cp_r 'coverage', ccout
  end
  system "open coverage/index.html" if PLATFORM['darwin']
end