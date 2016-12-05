module AssOle
  module Snippets
    #
    module Shared
      # @api private
      def self.mapped_mixin
        Module.new do
          define_method :_hash_to_object do |hash_, object_|
            hash_.each_with_object(object_) do |k_v, obj|
              obj.Insert((k_v[0].is_a?(Symbol) ? k_v[0].to_s : k_v[0]), k_v[1])
            end
          end
          private :_hash_to_object
        end
      end

      # Snippet for worcking with 1C Map obect
      module Map
        include Shared.mapped_mixin
        # Returns new Map builded from hash
        # @note If +key.is_a? Symbol+ key will be converts to +String+
        # @return [WIN32OLE]
        def map(hash_ = nil, **hash__)
          hash_ = hash__ if hash_.nil?
          _hash_to_object(hash_, newObject('Map'))
        end
      end

      # Snippet for worcking with 1C Structure obect
      module Structure
        include Shared.mapped_mixin
        # Returns new Structure builded from hash
        # @note (see Map#map)
        # @return [WIN32OLE]
        def structure(hash_ = nil, **hash__)
          hash_ = hash__ if hash_.nil?
          _hash_to_object(hash_, newObject('Structure'))
        end
      end
    end
  end
end
