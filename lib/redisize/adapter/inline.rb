module Redisize
   module Adapter
      class Inline
         class << self
            def enqueue method, *args
               Redisize.send(method, *args)
            end
         end
      end
   end
end
