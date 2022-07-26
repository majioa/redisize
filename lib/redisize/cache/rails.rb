module Redisize
   module Cache
      module Rails
         def redisize_cache_write key, object, options = {}
            ::Rails.cache.write(key, object, options)
         end

         def redisize_cache_read key
            ::Rails.cache.read(key)
         end

         def redisize_cache_fetch key, options = {}, &block
            ::Rails.cache.fetch(key, options, &block)
         end

         def redisize_cache_delete key
            ::Rails.cache.delete(key)
         end
      end
   end
end
