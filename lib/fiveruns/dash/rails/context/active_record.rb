module Fiveruns::Dash::Rails::Context
  
  module ActiveRecord
    
    def self.included(base)
      class << base
        Fiveruns::Dash::ActiveRecord::CLASS_METHODS.each do |meth|
          head = meth
          tail = ''
          head, tail = meth[0..(meth.length-2)], meth[-1..-1] if %w(? !).include? meth[-1..-1]
          self.class_eval <<-EOM
            def #{head}_with_dash_context#{tail}(*args, &block)
              Fiveruns::Dash::Rails::Context::ActiveRecord.with_model_context(self.name) do
                #{head}_without_dash_context#{tail}(*args, &block)
              end
            end
          EOM
          alias_method_chain(meth.to_sym, :dash_context)
        end
      end

      Fiveruns::Dash::ActiveRecord::INSTANCE_METHODS.each do |meth|
        head = meth
        tail = ''
        head, tail = meth[0..meth.length-2], meth[-1..-1] if %w(? !).include? meth[-1..-1]
        base.class_eval <<-EOM
          def #{head}_with_dash_context#{tail}(*args, &block)
            Fiveruns::Dash::Rails::Context::ActiveRecord.with_model_context(self.class.name) do
              #{head}_without_dash_context#{tail}(*args, &block)
            end
          end
        EOM
        base.alias_method_chain(meth.to_sym, :dash_context)
      end
    end

    def self.with_model_context(model_name)
      context = Fiveruns::Dash::Context.context
      # don't change context if model context has already been set.
      if context.size > 0 && context[-2] == 'model' && context[-1] == model_name
        return yield
      end

      original_context = Fiveruns::Dash::Context.context.dup
      begin
        if context[-2] == 'model'
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
    
  end
      
end