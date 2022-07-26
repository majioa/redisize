module Redisize
   module Adapter
      class Sidekiq
         include ::Sidekiq::Worker
         sidekiq_options queue: 'caching'
         sidekiq_options limits: { caching: 1 }
         sidekiq_options process_limits: { caching: 1 }

         def perform method, *args
            Redisize.send(method, *args)
         end

         class << self
            def enqueue *args
               self.perform_async(*args)
            end
         end
      end
   end
end
