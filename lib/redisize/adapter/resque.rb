module Redisize
   module Adapter
      class Resque
         @queue = :caching

         class << self
            def enqueue *args
               ::Resque.enqueue(self, *args)
            end

            def lock_workers _method, *_args
               @queue
            end

            def perform method, *args
               Redisize.send(method, *args)
            end
         end
      end
   end
end
