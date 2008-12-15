module Fiveruns::Dash::ActiveRecordContext
  
  def self.included(base)
    class << base
      self.send(:include, ClassMethods)
      alias_method_chain(:find_by_sql, :dash_context)
      alias_method_chain(:calculate, :dash_context)
    end
  end
  
  module ClassMethods
    def find_by_sql_with_dash_context(*args, &block)
      with_model_context do
        find_by_sql_without_dash_context(*args, &block)
      end
    end
    
    def calculate_with_dash_context(*args, &block)
      with_model_context do
        calculate_without_dash_context(*args, &block)
      end
    end

    private

    def with_model_context
      original_context = Fiveruns::Dash::Context.context.dup
      begin
        Fiveruns::Dash::Context.context << 'model'
        Fiveruns::Dash::Context.context << name
        return yield
      ensure
        Fiveruns::Dash::Context.set original_context
      end
    end
  end
end

# ActiveRecord ################################################################
Fiveruns::Dash.register_recipe :activerecord, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.added do
    ActiveRecord::Base.send(:include, Fiveruns::Dash::ActiveRecordContext)
  end
  recipe.time :ar_time, 'ActiveRecord Time', :methods => %w(
    ActiveRecord::Base.find_by_sql 
    ActiveRecord::Base.calculate
    ActiveRecord::Base.create
    ActiveRecord::Base.update 
    ActiveRecord::Base.update_all
    ActiveRecord::Base#update
    ActiveRecord::Base#save 
    ActiveRecord::Base#save!
    ActiveRecord::Base#destroy 
    ActiveRecord::Base.destroy 
    ActiveRecord::Base.destroy_all
    ActiveRecord::Base.delete 
    ActiveRecord::Base.delete_all), :reentrant => true

  recipe.time :db_time, 'Database Time', :methods => %w(ActiveRecord::ConnectionAdapters::AbstractAdapter#log)

  recipe.percentage :ar_util, 'ActiveRecord Utilization', :sources => %w(ar_time response_time) do |ar_time, response_time| 
    (ar_time / response_time) * 100.0
  end
  recipe.percentage :db_util, 'Database Utilization', :sources => %w(db_time response_time) do |db_time, response_time| 
    (db_time / response_time) * 100.0
  end

  recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      [[], Fiveruns::Dash::Context.context]
    end
  end
end

