Fiveruns::Dash.register_recipe :activerecord, :url => 'http://dash.fiveruns.com' do |recipe|
  finds = %w(ActiveRecord::Base.find ActiveRecord::Base.find_by_sql)
  recipe.time :find_time, 'Find Time', :methods => finds
  recipe.counter :finds, 'Finds', :incremented_by => finds

  creates = %w(ActiveRecord::Base.create)
  recipe.time :create_time, 'Create Time', :methods => creates
  recipe.counter :creates, 'Creates', :incremented_by => creates

  updates = %w(ActiveRecord::Base.update ActiveRecord::Base.update_all
              ActiveRecord::Base#update
              ActiveRecord::Base#save ActiveRecord::Base#save!)
  recipe.time :update_time, 'Update Time', :methods => updates
  recipe.counter :updates, 'Updates', :incremented_by => updates

  deletes  = %w(ActiveRecord::Base#destroy ActiveRecord::Base.destroy ActiveRecord::Base.destroy_all
               ActiveRecord::Base.delete ActiveRecord::Base.delete_all)
  recipe.time :delete_time, 'Delete Time', :methods => deletes
  recipe.counter :deletes, 'Deletes', :incremented_by => deletes
end

Fiveruns::Dash.register_recipe :rails, :url => 'http://dash.fiveruns.com' do |recipe|
  
  recipe.included do
    require File.dirname(__FILE__) << "/../lib/fiveruns/dash/rails"
    ActionController::Base.send(:include, Fiveruns::Dash::Rails::Context)
  end
  
  recipe.add_recipe :activerecord, :url => 'http://dash.fiveruns.com'
  
  recipe.find :recipe_name => :activerecord, :url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      name = if obj.is_a?(ActiveRecord::Base)
        obj.class.name
      else
        obj.name
      end
      Array(Fiveruns::Dash::Rails::Context.context.dup).push(:model, name)
    end
  end
  
end