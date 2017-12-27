module AssOle
  module Snippets
    module Shared
      # Mixin provides helpers for get 1C application platform version
      # compatibility
      module AppCompatibility
        is_ole_snippet

        # @return [Gem::Version] real version of 1C:Enterprise platform from
        #  +SystemInfo+ object
        def platform_version
          Gem::Version.new newObject('SystemInfo').AppVersion
        end

        # @return [String] application +CompatibilityMode+ as a string
        def app_compatibility_mode
          sTring(metaData.CompatibilityMode)
        end

        # @return [Gem::Version] application platform version compatibility
        def app_compatibility_version
          def app_compatibility_version_get
            return platform_version.segments.slice(0,3).join('.') if\
              app_compatibility_mode =~ %r{(НеИспользовать|DontUse)}i
            app_compatibility_mode.gsub(/(Версия|Version)/i,'').gsub(/_/,'.')
          end

          Gem::Version.new(app_compatibility_version_get)
        end
      end
    end
  end
end
