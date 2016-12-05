module AssOle
  module Snippets
    #
    module Shared
      # Snippet for worcking with 1C Array object
      module Array
        is_ole_snippet

        # Returns new 1C Array
        # @return [WIN32OLE]
        def array(*args)
          args_ = (args.size == 1) && (args[0].is_a? ::Array) ? args[0] : args
          args_.each_with_object(newObject('Array')) do |val, obj|
            obj.add val
          end
        end
      end
    end
  end
end
