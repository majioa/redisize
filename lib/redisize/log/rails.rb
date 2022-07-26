module Redisize
   module Log
      module Rails
         def redisize_log_info *args
            ::Rails.logger.info(*args)
         end

         def redisize_log_debug *args
            ::Rails.logger.debug(*args)
         end

         def redisize_log_error *args
            ::Rails.logger.error(*args)
         end
      end
   end
end
