module Redisize
   module ORM
      module ActiveRecord
         def self.included kls
            kls.class_eval do
               alias_method :__redisize_create_or_update, :create_or_update
               alias_method :__redisize_destroy, :destroy
               alias_method :__redisize_update_columns, :update_columns
               alias_method :__redisize_touch, :touch

               def create_or_update **args, &block
                  new_record = new_record?
                  state = __redisize_create_or_update(**args, &block)

                  new_record && deredisize_model || reredisize_instance

                  state
               end

               def update_columns **args
                  state = __redisize_update_columns(**args)

                  reredisize_instance

                  state
               end

               def touch **args
                  state = __redisize_touch(**args)

                  reredisize_instance

                  state
               end

               def destroy
                  state = __redisize_destroy

                  %i(deredisize_instance deredisize_model).each {|m| send(m) }

                  state
               end
            end
         end
      end
   end
end
