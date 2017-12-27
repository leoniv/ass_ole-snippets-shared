require 'ass_ole/snippets/shared/version'
require 'ass_ole'

module AssOle
  module Snippets
    # Shared Ole snippets.
    #
    # Object included snippets must +respond_to? ole_connector+ and returns
    # 1C OLE connector or includes +AssOle+ runtime using: +like_ole_runtime+
    # method defined in +ass_ole+ gem.
    # @example
    #   require 'ass_ole'
    #   require 'ass_ole/snippets/shared'
    #   require 'ass_maintainer/info_base'
    #
    #   # External connection runtime
    #   module ExternalRuntime
    #     is_ole_runtime :external
    #   end
    #
    #   class Worker
    #     like_ole_runtime ExternalRuntime
    #     include AssOle::Snippets::Shared::Query
    #
    #     def initialize(connection_string)
    #       ole_runtime_get.run AssMaintainer::InfoBase.new('ib_name', connection_string)
    #     end
    #
    #     def select(value)
    #       query('select &arg as arg', arg: value).Execute.Unload.Get(0).arg
    #     end
    #   end
    #
    #   Worker.new('File="path"').select('Hello') #=> "Hello"
    module Shared
      # Snippet for serialize and deserilize 1C objects to xml
      # @note In external runtime it will be cause of a fail in +InfoBase#rm!+
      #  '... /1Cv8.1CD (Errno::EBUSY)'  because external connection
      #  realy keep alive
      module XMLSerializer
        is_ole_snippet

        # Serialize 1C oject to XML string
        # @param obj [WIN32OLE] 1C object
        # @return [String]
        def to_xml(obj)
          zxml = newObject 'XMLWriter'
          zxml.SetString
          xDTOSerializer.WriteXML zxml, obj
          zxml.close
        end

        # Serialize 1C oject to XML file
        # @param obj [WIN32OLE] 1C object
        # @param xml_file [#path String] target file path
        # @return +xml_file+
        def to_xml_file(obj, xml_file)
          zxml = newObject 'XMLWriter'
          path_ = xml_file.respond_to?(:path) ? xml_file.path : xml_file
          zxml.openFile(real_win_path(path_))
          xDTOSerializer.WriteXML zxml, obj
          xml_file
        ensure
          zxml.close
        end

        # Deserialize 1C object from XML srtring
        # @param xml [String] xml string
        # @return [WIN32OLE] 1C object
        def from_xml(xml)
          zxml = newObject 'XMLReader'
          zxml.SetString xml
          xDTOSerializer.ReadXml zxml
        end

        # Deserialize 1C object from XML file
        # @param xml_file [#path String] path to xml file
        # @return [WIN32OLE] 1C object
        def from_xml_file(xml_file)
          zxml = newObject 'XMLReader'
          path_ = xml_file.respond_to?(:path) ? xml_file.path : xml_file
          zxml.openFile(real_win_path(path_))
          obj = xDTOSerializer.ReadXml zxml
          obj
        ensure
          zxml.close
        end
      end

      # Snippet for worcking with 1C Query object
      module Query
        is_ole_snippet

        # Returns 1C query object
        # @return [WIN32OLE]
        def query(text, temp_tables_manager_ = nil, **params)
          q = newObject('Query', text)
          q.TempTablesManager = temp_tables_manager_ || temp_tables_manager
          params.each do |k, v|
            q.SetParameter(k.to_s, v)
          end
          q
        end

        # Returns 1C TempTablesManager
        # @return [WIN32OLE]
        def temp_tables_manager
          newObject 'TempTablesManager'
        end
      end

      # @deprecated Use {InTransactionDo} instead
      # @todo remove module in v1.0.0
      # Do in transaction wrapper
      module Transaction
        is_ole_snippet

        def self.depricate
          Kernel.warn '[DEPRICATION]'\
            " '#{self.name}` is deprecated and will be"\
            " removed soon. Please use "\
            '\'AssOle::Snipptes::Shared::InTransactionDo` instead.'\
        end

        [method(:included), method(:extended)].each do |old_method|
          name = old_method.name
          old = "_depricate_#{name}"
          singleton_class.class_eval {
            alias_method old, name
            define_method name do |*args, &block|
              AssOle::Snippets::Shared::Transaction.depricate
              send old, *args, &block
            end
          }
        end

        # rubocop:disable Metrics/MethodLength

        # @deprecated Use {InTransactionDo#in_transaction} instead
        # @raise [RuntimeError] if nested transaction
        def do_in_transaction(&block)
          AssOle::Snippets::Shared::Transaction.depricate
          fail ArgumentError, 'Block require' unless block_given?
          fail 'Nested transaction is mindless in 1C runtime' if\
            transactionActive
          begin
            beginTransAction
            r = instance_eval(&block)
            commitTransAction
            r
          rescue StandardError => e
            rollBackTransaction
            raise e
          end
        end

        # rubocop:enable Metrics/MethodLength
      end

      require 'ass_ole/snippets/shared/mapped'
      require 'ass_ole/snippets/shared/array'
      require 'ass_ole/snippets/shared/binary_data'
      require 'ass_ole/snippets/shared/value_table'
      require 'ass_ole/snippets/shared/in_transaction_do'
      require 'ass_ole/snippets/shared/app_compatibility'
    end
  end
end
