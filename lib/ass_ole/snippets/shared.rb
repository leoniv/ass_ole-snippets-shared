require "ass_ole/snippets/shared/version"

module AssOle
  module Snippets
    module Shared
      # Snippet for serialize and deserilize 1C objects to xml
      module XMLSerializer
        extend AssOle::Snippets::IsSnippet

        def to_xml(obj)
          zxml = newObject 'XMLWriter'
          zxml.SetString
          xDTOSerializer.WriteXML zxml, obj
          zxml.close
        end

        def to_xml_file(obj, xml_file)
          zxml = newObject 'XMLWriter'
          _path = xml_file.respond_to?(:path) ? xml_file.path : xml_file
          zxml.openFile(win_path(_path))
          xDTOSerializer.WriteXML zxml, obj
          zxml.close
          xml_file
        end

        def from_xml(xml)
          fail 'FIXME'
        end

        def from_xml_file(xml_file)
          fail 'FIXME'
        end
      end

      # Snippet for worcking with 1C Query object
      module Query
        extend AssOle::Snippets::IsSnippet

        def query(text, temp_tables_manager = nil, **params)
          q = newObject('Query', text)
          q.TempTablesManager = temp_tables_manager if\
            temp_tables_manager
          params.each do |k,v|
            q.SetParameter(k.to_s,v)
          end
          q
        end
      end
    end
  end
end
