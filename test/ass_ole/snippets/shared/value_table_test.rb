require 'test_helper'

module AssOle::Snippets::SharedTest
  describe AssOle::Snippets::Shared::ValueTable do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#value_table wrapper with block' do
      actual = value_table :f1, :f2, :f3 do |vt_wrapper|
        3.times do |r|
          vt_wrapper.add do |row|
            row.f1 = r
            row.f2 = 10 + r
            row.f3 = 20 + r
          end
        end
      end

      actual.Count.must_equal 3

      3.times do |f|
        3.times do |r|
          actual.Get(r).send("f#{f+1}").must_equal(f * 10 + r)
        end
      end
    end

    it '#value_table' do
      actual = value_table :f1, :f2, :f3
      actual.Columns.Count.must_equal 3
      actual.Count.must_equal 0
    end

    it '#value_table with block' do
      actual = value_table :f1, :f2, :f3 do |vt_wrapper|
        # Add new ValueTableRow with values
        ole_row = vt_wrapper.add f1: 0, f2: 1, f3: nil

        vt_wrapper.must_be_instance_of AssOle::Snippets::Shared::ValueTable::Wrapper
        vt_wrapper.Columns.Count.must_equal 3, 'pass #Columns into #ole'
        vt_wrapper.Count.must_equal 1, 'pass #Count into #ole'

        ole_row.must_be_instance_of WIN32OLE
        ole_row.f1.must_equal 0
        ole_row.f2.must_equal 1
        ole_row.f3.must_be_nil
      end

      actual.Get(0).f1.must_equal 0
      actual.Get(0).f2.must_equal 1
      actual.Get(0).f3.must_be_nil
    end
  end

end
