require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

require File.dirname(__FILE__) << "/lib/fiveruns/dash/rails/version"

NAME = "fiveruns_dash_rails"
AUTHOR = "FiveRuns Development Team"
EMAIL = "dev@fiveruns.com"
HOMEPAGE = "http://dash.fiveruns.com/"
SUMMARY = "FiveRuns Dash Rails recipes"
GEM_VERSION = Fiveruns::Dash::Rails::Version::STRING

spec = Gem::Specification.new do |s|
  s.rubyforge_project = 'fiveruns'
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = %w()
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('fiveruns_dash')
  s.require_path = 'lib'
  s.files = %w(Rakefile) + FileList["{lib,test}/**/*"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.test_files = FileList['test/*_test.rb']
  t.libs  << 'lib'
end

task :default => :test

sudo = RUBY_PLATFORM[/win/] ? '' : 'sudo '

desc "Install as a gem"
task :install => [:package] do
  sh %{#{sudo}gem install pkg/#{NAME}-#{GEM_VERSION} --no-update-sources}
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => :package do
    sh %{#{sudo}jruby -S gem install #{install_home} pkg/#{NAME}-#{GEM_VERSION}.gem --no-rdoc --no-ri}
  end
  
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

task :cruise => [:test, :coverage]