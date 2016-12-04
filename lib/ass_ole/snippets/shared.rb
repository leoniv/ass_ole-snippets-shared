require 'ass_ole/snippets/shared/version'
require 'ass_ole'

module AssOle
  module Snippets
    module Shared
      # Snippet for serialize and deserilize 1C objects to xml
      module XMLSerializer
        is_ole_snippet

        # Serialize 1C oject to XML string
        def to_xml(obj)
          zxml = newObject 'XMLWriter'
          zxml.SetString
          xDTOSerializer.WriteXML zxml, obj
          zxml.close
        end

        # Serialize 1C oject to XML file
        def to_xml_file(obj, xml_file)
          zxml = newObject 'XMLWriter'
          _path = xml_file.respond_to?(:path) ? xml_file.path : xml_file
          zxml.openFile(win_path(_path))
          xDTOSerializer.WriteXML zxml, obj
          zxml.close
          xml_file
        end

        # Deserialize 1C object from XML srtring
        def from_xml(xml)
          fail 'FIXME'
        end

        # Deserialize 1C object from XML file
        def from_xml_file(xml_file)
          fail 'FIXME'
        end
      end

      # Snippet for worcking with 1C Query object
      module Query
        is_ole_snippet

        # Returns 1C query object
        # @return [WIN32OLE]
        def query(text, temp_tables_manager = nil, **params)
          q = newObject('Query', text)
          q.TempTablesManager = temp_tables_manager || temp_tables_manager()
          params.each do |k,v|
            q.SetParameter(k.to_s,v)
          end
          q
        end

        # Returns 1C TempTablesManager
        # @return [WIN32OLE]
        def temp_tables_manager
          newObject 'TempTablesManager'
        end
      end

      # Do in transaction wrapper
      module Transaction
        is_ole_snippet

        # @fail [RuntimeError] if nested transaction
        def do_in_transaction(&block)
          fail ArgumentError, 'Block require' unless block_given?
          fail 'Nested transaction is mindless in 1C runtime' if\
            transactionActive
          begin
            beginTransAction
            r = instance_eval(&block)
            commitTransAction
            r
          rescue Exception => e
            rollBackTransaction
            fail e
          end
        end
      end
    end
  end
end
