module Fiveruns::Dash::ActiveRecordContext
  CLASS_METHODS = %w(find find_by_sql calculate create update_all destroy destroy_all delete delete_all)
  INSTANCE_METHODS = %w(update save destroy)

  def self.included(base)
    class << base
      CLASS_METHODS.each do |meth|
        self.class_eval <<-EOM
          def #{meth}_with_dash_context(*args, &block)
            Fiveruns::Dash::ActiveRecordContext.with_model_context(self.name) do
              #{meth}_without_dash_context(*args, &block)
            end
          end
        EOM
        alias_method_chain(meth.to_sym, :dash_context)
      end
    end

    INSTANCE_METHODS.each do |meth|
      base.class_eval <<-EOM
        def #{meth}_with_dash_context(*args, &block)
          Fiveruns::Dash::ActiveRecordContext.with_model_context(self.class.name) do
            #{meth}_without_dash_context(*args, &block)
          end
        end
      EOM
      base.alias_method_chain(meth.to_sym, :dash_context)
    end
  end

  def self.with_model_context(model_name)
    ctx = Fiveruns::Dash::Context.context
    # don't change context if model context has already been set.
    return yield if ctx.size > 0 && ctx[-2] == 'model'

    original_context = Fiveruns::Dash::Context.context.dup
    begin
      Fiveruns::Dash::Context.context << 'model'
      Fiveruns::Dash::Context.context << model_name
      return yield
    ensure
      Fiveruns::Dash::Context.set original_context
    end
  end
  
  def self.all_methods
    CLASS_METHODS.map { |m| "ActiveRecord::Base.#{m}" } + INSTANCE_METHODS.map { |m| "ActiveRecord::Base##{m}"}
  end

end

# ActiveRecord ################################################################

Fiveruns::Dash.register_recipe :activerecord, :url => 'http://dash.fiveruns.com' do |recipe|
  recipe.added do
    ActiveRecord::Base.send(:include, Fiveruns::Dash::ActiveRecordContext)
  end
  recipe.time :ar_time, 'ActiveRecord Time', :methods => Fiveruns::Dash::ActiveRecordContext.all_methods, :reentrant => true
  recipe.time :db_time, 'Database Time', :methods => %w(ActiveRecord::ConnectionAdapters::AbstractAdapter#log)

  # We need a way to get the total time for a request/operation so that we can
  # calculate the relative percentage used by AR/DB.  Default to "response_time" for the Rails
  # recipe but daemons can set this constant to provide their own total time metric.
  total_time = recipe.options[:ar_total_time] ? recipe.options[:ar_total_time] : "response_time"

  recipe.percentage :ar_util, 'ActiveRecord Utilization', :sources => ["ar_time", total_time] do |ar_time, all_time|
    (ar_time / all_time) * 100.0
  end
  recipe.percentage :db_util, 'Database Utilization', :sources => ["db_time", total_time] do |db_time, all_time|
    (db_time / all_time) * 100.0
  end

  recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      [[], Fiveruns::Dash::Context.context]
    end
  end
end

