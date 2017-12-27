require 'test_helper'

module AssOle::Snippets::SharedTest
  describe AssOle::Snippets::Shared::AppCompatibility do
    describe 'smoky tests with real ole runtime' do
      like_ole_runtime EXT_RUNTIME
      include AssOle::Snippets::Shared::AppCompatibility

      it '#platform_version' do
        platform_version.must_be_instance_of Gem::Version
        platform_version.to_s.must_match %r{^\d+\.\d+\.\d+\.\d+$}
      end

      it '#app_compatibility_mode' do
        app_compatibility_mode.must_match %r{(DontUse|НеИспользовать)}i
      end

      it '#app_compatibility_version' do
        app_compatibility_version.must_be_instance_of Gem::Version
        app_compatibility_version.to_s.must_match %r{^\d+\.\d+\.\d+$}
      end
    end

    describe '#app_compatibility_version with mocked ole runtime' do
      def mock(comp_mode = nil)
        @mock ||= Class.new do
          like_ole_runtime EXT_RUNTIME
          include AssOle::Snippets::Shared::AppCompatibility

          attr_reader :app_compatibility_mode
          def initialize(comp_mode)
            @app_compatibility_mode = comp_mode
          end
        end.new(comp_mode)
      end

      it 'when app_compatibility == DontUse' do
        mock('dontUse').app_compatibility_version.to_s
          .must_equal mock.platform_version.segments.slice(0,3).join('.')
      end

      it 'when app_compatibility == НеИспользовать' do
        mock('неИспользовать').app_compatibility_version.to_s
          .must_equal mock.platform_version.segments.slice(0,3).join('.')
      end

      it 'when app_compatibility == Version8_3_8' do
        mock('version8_3_8').app_compatibility_version.to_s.must_equal '8.3.8'
      end

      it 'when app_compatibility == Версия8_3_8' do
        mock('версия8_3_8').app_compatibility_version.to_s.must_equal '8.3.8'
      end
    end
  end
end
