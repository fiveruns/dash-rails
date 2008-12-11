
module Fiveruns::Dash::Rails::ActiveRecordContext
  
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
