module AssOle
  module Snippets
    #
    module Shared
      # Snippet for worcking with 1C +ValueTable+ object
      # @example
      #  like_ole_runtime External
      #  include AssOle::Snippets::Shared::ValueTable
      #
      #  # Make new ValueTable with f1, f2, f3 columns
      #  value_table :f1, :f2, :f3 # => WIN32OLE
      #
      #  # Make new ValueTable and insert into 1 row
      #  actual = value_table :f1, :f2, :f3 do |vt_wrapper|
      #    vt_wrapper.add f1: 0, f2: 1, f3: 2
      #  end # => WIN32OLE
      #
      #  # Make new ValueTable without typing of columns and insert into 3 rows
      #  value_table :f1, :f2, :f3 do |vt_wrapper|
      #    3.times do |r|
      #      vt_wrapper.add do |row|
      #        row.f1 = r
      #        row.f2 = 10 + r
      #        row.f3 = 20 + r
      #      end
      #    end
      #  end # => WIN32OLE
      #
      #  # Make new ValueTable with typing of columns and insert into 3 rows
      #  value_table f1:%w{String Boolean}, f2:[String, Date], f3:'String,Date' do |vt_wrapper|
      #    3.times do |r|
      #      vt_wrapper.add do |row|
      #        row.f1 = r
      #        row.f2 = 10 + r
      #        row.f3 = 20 + r
      #      end
      #    end
      #  end # => WIN32OLE
      module ValueTable
        # Warapper for add rows into +ValueTable+
        # @api private
        class Wrapper
          # @return [WIN32OLE] +ValueTable+ object
          attr_reader :ole
          def initialize(ole)
            @ole = ole
          end

          # Add ValueTableRow into +ValueTable+
          # @return [WIN32OLE] 1C +ValueTableRow+ object
          # @param options [Hash] +ValueTableRow+ values
          # @api public
          # @yield [WIN32OLE] added +ValueTableRow+ object
          def add(**options, &block)
            r = ole.Add
            options.each do |k, v|
              r.send("#{k}=", v) unless v.nil?
            end
            yield r if block_given?
            r
          end

          # Pass other into {#ole}
          def method_missing(method, *args)
            ole.send(method, *args)
          end
        end

        module Columns
          def self.make(vtable, columns, columns_with_types, ole_connector)
            to_columns_with_types(columns).merge(columns_with_types)
              .each do |col, types|
              type_desc_ = type_desc(types, ole_connector)
              vtable.Columns.Add(col.to_s, type_desc_) if type_desc_
              vtable.Columns.Add(col.to_s) unless type_desc_
            end
            vtable.Columns
          end

          def self.type_desc(types, ole_connector)
            return unless types
            types_ = types.clone
            types_ = types_.split(',') if types.is_a? String
            ole_connector.newObject('TypeDescription', types_.join(','))
          end

          def self.to_columns_with_types(columns)
            r = {}
            columns.each do |col|
              r[col.to_sym] = nil
            end
            r
          end
        end

        # @param columns [Array] +ValueTable+ columns
        # @param columns_with_types [Hash] +ValueTable+ columns with column
        #  type names [Array] like %w{TypeName OtheTypeName}
        #  or [String] like 'TypeName, OtheTypeName'
        # @yield [Wrapper]
        # @return [WIN32OLE] 1C +ValueTable+ object
        def value_table(*columns, **columns_with_types, &block)
          r = newObject('ValueTable')
          Columns.make(r, columns, columns_with_types, ole_connector)
          r = Wrapper.new(r)
          yield r if block_given?
          r.ole
        end
      end
    end
  end
end
