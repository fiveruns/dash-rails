NAME = "dash-rails"
AUTHOR = "FiveRuns Development Team"
EMAIL = "dev@fiveruns.com"
HOMEPAGE = "http://dash.fiveruns.com/"
SUMMARY = "FiveRuns Dash library for Ruby on Rails"

# Important: Make sure you modify this in version.rb, too.
GEM_VERSION = '0.6.5'

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
  s.add_dependency('fiveruns-dash-ruby', '>= 0.6.2')
  s.require_path = 'lib'
  s.files = %w(Rakefile init.rb) + Dir.glob("{lib,test,dash,rails}/**/*")
end