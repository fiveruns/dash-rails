module Fiveruns::Dash::ActiveRecordContext
  CLASS_METHODS = %w(find find_by_sql calculate create create! update_all destroy destroy_all delete delete_all)
  INSTANCE_METHODS = %w(update save save! destroy)

  def self.included(base)
    class << base
      CLASS_METHODS.each do |meth|
        head = meth
        tail = ''
        head, tail = meth[0..(meth.length-2)], meth[-1..-1] if %w(? !).include? meth[-1..-1]
        self.class_eval <<-EOM
          def #{head}_with_dash_context#{tail}(*args, &block)
            Fiveruns::Dash::ActiveRecordContext.with_model_context(self.name) do
              #{head}_without_dash_context#{tail}(*args, &block)
            end
          end
        EOM
        alias_method_chain(meth.to_sym, :dash_context)
      end
    end

    INSTANCE_METHODS.each do |meth|
      head = meth
      tail = ''
      head, tail = meth[0..meth.length-2], meth[-1..-1] if %w(? !).include? meth[-1..-1]
      base.class_eval <<-EOM
        def #{head}_with_dash_context#{tail}(*args, &block)
          Fiveruns::Dash::ActiveRecordContext.with_model_context(self.class.name) do
            #{head}_without_dash_context#{tail}(*args, &block)
          end
        end
      EOM
      base.alias_method_chain(meth.to_sym, :dash_context)
    end
  end

  def self.with_model_context(model_name)
    ctx = Fiveruns::Dash::Context.context
    # don't change context if model context has already been set.
    return yield if ctx.size > 0 && ctx[-2] == 'model' && ctx[-1] == model_name

    original_context = Fiveruns::Dash::Context.context.dup
    begin
      if ctx[-2] == 'model'
        # Some models will internally load other models.
        Fiveruns::Dash::Context.context.pop
        Fiveruns::Dash::Context.context << model_name
      else
        Fiveruns::Dash::Context.context << 'model'
        Fiveruns::Dash::Context.context << model_name
      end
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
  # We need a way to get the total time for a request/operation so that we can
  # calculate the relative percentage used by AR/DB.  Default to "response_time" for the Rails
  # recipe but daemons can set this constant to provide their own total time metric.
  total_time = recipe.options[:ar_total_time] ? recipe.options[:ar_total_time] : "response_time"

  recipe.time :ar_time, 'ActiveRecord Time', :methods => Fiveruns::Dash::ActiveRecordContext.all_methods, :reentrant => true, :only_within => total_time
  recipe.time :db_time, 'Database Time', :methods => %w(ActiveRecord::ConnectionAdapters::AbstractAdapter#log), :only_within => total_time

  recipe.percentage :ar_util, 'ActiveRecord Utilization', :sources => ["ar_time", total_time] do |ar_time, all_time|
    all_time == 0 ? 0 : (ar_time / all_time) * 100.0
  end
  recipe.percentage :db_util, 'Database Utilization', :sources => ["db_time", total_time] do |db_time, all_time|
    all_time == 0 ? 0 : (db_time / all_time) * 100.0
  end

  recipe.modify :recipe_name => :activerecord, :recipe_url => 'http://dash.fiveruns.com' do |metric|
    metric.find_context_with do |obj, *args|
      if Fiveruns::Dash::Context.context == []
        []
      else
        [[], Fiveruns::Dash::Context.context]
      end
    end
  end

  recipe.added do
    ActiveRecord::Base.send(:include, Fiveruns::Dash::ActiveRecordContext)
  end
end

