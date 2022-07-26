require "redisize/version"

module Redisize
   class << self
      attr_writer :adapter

      ADAPTERS = {
         sidekiq: :Sidekiq, # req: Sidekiq::LimitFetch
         resque: :Resque,
         inline: :TrueClass
      }

      ORMS = {
         ActiveRecord: 'active_record'
      }

      LOGS = {
         Rails: 'rails'
      }

      CACHES = {
         Rails: 'rails'
      }

      # system method
      def included kls
         kls.extend(Redisize::ClassMethods)

         # init orm, log, and cache
         init_orm_for(kls)
         init_log_for(kls)
         init_cache_for(kls)
      end

      def init_orm_for kls
         orm = kls.ancestors.reduce(nil) { |res, anc| res || ORMS.keys.find {|re| /#{re}/ =~ anc.to_s } }

         if orm
            require("redisize/orm/#{ORMS[orm]}")
            kls.include(Redisize::ORM.const_get(orm))
         end
      end

      def init_log_for kls
         log = Object.constants.reduce(nil) { |res, anc| res || LOGS.keys.find {|re| /#{re}/ =~ anc.to_s } }

         if log
            require("redisize/log/#{LOGS[log]}")
            Redisize.include(Redisize::Log.const_get(log))
            Redisize.extend(Redisize::Log.const_get(log))
            kls.extend(Redisize::Log.const_get(log))
         end
      end

      def init_cache_for kls
         cache = Object.constants.reduce(nil) { |res, anc| res || CACHES.keys.find {|re| /#{re}/ =~ anc.to_s } }

         if cache
            require("redisize/cache/#{CACHES[cache]}")
            Redisize.include(Redisize::Cache.const_get(cache))
            Redisize.extend(Redisize::Cache.const_get(cache))
            kls.extend(Redisize::Cache.const_get(cache))
         end
      end

      def adapter_kind= value
         self.adapter = acquire_adapter(ADAPTERS[value] && value || :inline)
      end

      def acquire_adapter kind
         require("redisize/adapter/#{kind}")
         Redisize::Adapter.const_get(kind.capitalize)
      end

      def adapter
         @adapter ||=
            ADAPTERS.reduce(nil) do |res, (kind, prc)|
               res || Object.constants.include?(prc) && acquire_adapter(kind) || nil
            end
      end

      def enqueue method, *args
         adapter.enqueue(method, *args)
      end

      def filtered_for attrs, klass
         filtered = attrs.select {|attr| klass.attribute_types.keys.include?(attr) }
      end

      def assign_reverse_key key, host_key
         # binding.pry
         if value = redisize_cache_read(key)
            redisize_cache_write(key, value | [ host_key ], expires_in: 1.day)
            redisize_log_debug("Updated key #{key.inspect} with value #{host_key.inspect}")
         else
            redisize_cache_write(key, [ host_key ], expires_in: 1.day)
            redisize_log_debug("Created key #{key.inspect} with value #{host_key.inspect}")
         end
      end

      def drop_key key
         # binding.pry
         if value = redisize_cache_read(key)
            if key.first == "meta"
               size = value.size

               value.each { |rkey| drop_key(rkey) }
            end

            redisize_log_debug("Removed key #{key.inspect}#{size && " with #{size} subkeys"}")
            redisize_cache_delete(key)
         end
      end

      def rekey key, type = "meta"
         [type.to_s] + key[1..-1]
      end

      def key_name_for model_name, attrs, type = "meta"
         primary_key = model_name.constantize.primary_key
         [type, model_name, primary_key, attrs[primary_key].to_s]
      end

      def parse_sql_key key
         key[-1].split(/\s(join|from)\s/i)[1..-1].map do |part|
            part.strip.split(/[\s\"]/).reject {|x| x.blank? }.first
         end.uniq.map do |table|
            table.singularize.camelize.constantize rescue nil
         end.compact.each do |klass|
            assign_reverse_key(["meta", klass.name], key)
         end
      end

      def parse_instance_attrs model_name, attrs, key
         model = model_name.constantize
         children =
            attrs.map do |x, value|
               (value.is_a?(Array) || value.is_a?(Hash)) && x || nil
            end.compact

         children.each do |many|
            name = /^_(?<_name>.*)/ =~ many && _name || many.to_s

            instance = nil
            if klass = model.reflections[name]&.klass || many.singularize.camelize.constantize rescue nil
               attres_in = attrs[many]
               attres = attres_in.is_a?(Hash) && [attres_in] || attres_in
               attres.each do |attrs|
                  if attrs[klass.primary_key]
                     assign_reverse_key(key_name_for(klass.name, attrs), key)
                  else
                     assign_reverse_key(["meta", klass.name], key)
                  end
                  parse_instance_attrs(klass.name, attrs, key)
               end

               assign_reverse_key(["meta", klass.name], key)
            end
         end
      end

      def as_json_for instance
         instance.attribute_names.map {|x|[x, instance.read_attribute(x)] }.to_h
      end

      ### internal methods for enqueued proceeds
      #
      def redisize_model_metas metakey, model_name, attrs, key
         # binding.pry
         drop_key(metakey)
         drop_key(metakey[0..1])
         parse_instance_attrs(model_name, attrs, key)
         assign_reverse_key(metakey, key)
      end

      # +redisize_sql_metas+ updates all the meta keys for the result value
      #
      def redisize_sql_metas key, attres
         model_name = key[1]
         primary_key = key[2]

         # binding.pry
         attres.map do |attrs|
            metakey = ["meta", model_name, primary_key, attrs[primary_key]]

            parse_instance_attrs(model_name, attrs, key)
            assign_reverse_key(metakey, key)
         end

         parse_sql_key(key)
      end

      def deredisize_instance_metas key
         metakey = rekey(key)

         # binding.pry
         drop_key(metakey)
         redisize_cache_delete(key)
      end

      def reredisize_instance_metas key
         metakey = rekey(key)
         # binding.pry

         drop_key(metakey)
         assign_reverse_key(metakey, key)
      end

      def deredisize_model_metas model_name
         # binding.pry
         drop_key(["meta", model_name])
      end

      def deredisize_json_metas key
         # binding.pry
         drop_key(key)
      end

      def redisize_json_metas key, attrs
         metakey = key_name_for(key[1], attrs)

         # binding.pry
         parse_instance_attrs(key[1], attrs, key)
         assign_reverse_key(metakey, key)
      end
   end

   # self -> model instance
   def redisize_json scheme, &block
      primary_key = self.class.primary_key
      key = ["json", self.class.polymorphic_name, primary_key, self[primary_key].to_s, scheme]

      # binding.pry
      redisize_cache_fetch(key, expires_in: 1.week) do
         value = block.call

         Redisize.enqueue(:redisize_json_metas, key, value)

         value
      end
   end

   # self -> model instance
   def deredisize_json scheme, &block
      primary_key = self.class.primary_key
      key = ["json", self.class.polymorphic_name, primary_key, self[primary_key], scheme]

      # binding.pry
      Redisize.enqueue(:deredisize_json_metas, key)
   end

   # self -> model instance
   def deredisize_model
      Redisize.enqueue(:deredisize_model_metas, self.class.polymorphic_name)
   end

   # self -> model instance
   def reredisize_instance
      attrs = Redisize.as_json_for(self)
      key = Redisize.key_name_for(self.class.polymorphic_name, attrs, "instance")

      # binding.pry
      redisize_cache_write(key, self, expires_in: 1000.years)
      Redisize.enqueue(:reredisize_instance_metas, key)
   end

   # self -> model instance
   def deredisize_instance
      attrs = Redisize.as_json_for(self)
      key = Redisize.key_name_for(self.class.polymorphic_name, attrs, "instance")

      # binding.pry
      Redisize.enqueue(:deredisize_instance_metas, key)
   end

   module ClassMethods
      # self -> model class
      def redisize_sql &block
         key = ["sql", self.name, self.primary_key, self.all.to_sql]

         # binding.pry
         redisize_cache_fetch(key, expires_in: 1.day) do
            value = block.call

            Redisize.enqueue(:redisize_sql_metas, key, value)

            value
         end
      end

      # self -> model class
      def redisize_model value, options = {}, &block
         primary_key = options.fetch(:by_key, self.primary_key).to_s
         key = ["instance", name, primary_key, value]
         metakey = ["meta", self.class.polymorphic_name, primary_key, value]

         # binding.pry
         redisize_cache_fetch(key, expires_in: 1.week) do
            if result = block.call
               Redisize.enqueue(:redisize_model_metas, metakey, self.name, Redisize.as_json_for(result), key)
            end

            result
         end
      end
   end
end
