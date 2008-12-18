require File.dirname(__FILE__) << "/test_helper"

class ActiverecordTest < Test::Unit::TestCase

  context "Metric" do
    
    should "print sql" do
      child = fork do
        FileUtils.rm_f File.join(File.dirname(__FILE__), 'test.sqlite3')
        ActiveRecord::Base.configurations = { 'test' => { 'database' => 'test.sqlite3', 'adapter' => 'sqlite3' }}
        ActiveRecord::Base.establish_connection
        ActiveRecord::Base.connection.execute("create table test_models (id integer PRIMARY KEY, name varchar(32) not null)")
  
        class TestModel < ActiveRecord::Base
        end

        class TestEngine
          def doit
            sleep 1
            100.times do
              t = TestModel.create!(:name => 'foo')
              t.destroy
            end
          end
        end
        
        require 'fiveruns/dash'
        require 'fiveruns/dash/recipes/activerecord'
        
        eval <<-MOCK
          module Fiveruns::Dash
            class Reporter
              private
              def run
              end
            end
          end
        MOCK
        
        Fiveruns::Dash.register_recipe :tester, :url => 'http://dash.fiveruns.com' do |recipe|
          recipe.time :test_time, 'Test Time', :method => 'ActiverecordTest::TestEngine#doit'
        end
        Fiveruns::Dash.configure :app => '666', :ar_total_time => 'test_time' do |config|
          config.add_recipe :ruby
          config.add_recipe :activerecord
          config.add_recipe :tester
        end
#        Fiveruns::Dash.session.reporter.interval = 60
        Fiveruns::Dash.session.start(true)

        TestEngine.new.doit

        Fiveruns::Dash.session.data.each do |hsh| 
          puts "#{hsh[:name]}: #{hsh[:values].inspect}"
        end
      end
      Process.wait
    end
    
  end
end