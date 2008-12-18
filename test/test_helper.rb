RAILS_ENV='test'
RAILS_ROOT=File.dirname(__FILE__)
require 'test/unit'
require 'logger'
require 'rubygems'

begin
  require 'shoulda'
  require 'flexmock/test_unit'
  require 'fake_web'
rescue
  puts "Please install the Shoulda, FakeWeb and flexmock gems to run the Dash plugin tests."
end

require 'shoulda'
require 'flexmock/test_unit'

RAILS_DEFAULT_LOGGER=Logger.new(STDOUT)
require 'active_record'
require 'action_controller'
require 'action_controller/test_process'
require 'action_controller/test_case'
require 'action_view'

$:.unshift(File.dirname(__FILE__) << '/../lib')
$:.unshift(File.dirname(__FILE__) << '/../../fiveruns_dash/lib')

class Test::Unit::TestCase

end
