module AssOle
  module Snippets
    module Shared
      # Snippet for puck/unpack
      # data to/from 1C BinaryData
      module BinaryData
        require 'tempfile'
        is_ole_snippet

        # @api private
        class TempFile
          include AssOle::Snippets::IsSnippet::WinPath

          attr_reader :data
          def initialize(data)
            @data = data
          end

          def win_path
            real_win_path path
          end

          def write
            temp_file.write(data)
            temp_file.close
          end

          def read
            temp_file.open
            temp_file.read
          end

          def temp_file
            @temp_file ||= Tempfile.new('ass_ole_bin_data')
          end

          def exist?
            return false unless path
            File.exist? path
          end

          def rm!
            temp_file.unlink if exist?
          end

          def path
            temp_file.path
          end
        end

        # Packing data to 1C BinaryData
        # @param data data for packing
        # @return [WIN32OLE]
        def binary_data(data)
          temp_file = TempFile.new(data)
          temp_file.write
          result = newObject('BinaryData', temp_file.win_path)
          result
        ensure
          temp_file.rm!
        end

        # Unpacking data form 1C BinaryData
        # @param ole_bin_data [WIN32OLE] 1C BinaryData
        def binary_data_get(ole_bin_data)
          temp_file = TempFile.new(nil)
          temp_file.temp_file.close
          ole_bin_data.Write(temp_file.win_path)
          temp_file.read
        ensure
          temp_file.rm!
        end
      end
    end
  end
end
