module Redisize
   module ORM
      module ActiveRecord
         def self.included kls
            kls.class_eval do
               after_create :deredisize_model
               after_save :reredisize_instance
               after_destroy :deredisize_instance, :deredisize_model
            end
         end
      end
   end
end
