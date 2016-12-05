require 'test_helper'

module AssOle::Snippets::SharedTest
  describe AssOle::Snippets::Shared::Array do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#array [1, 2, 3 ...]' do
      a = array [0, 1, 2, 3, 4, 5, 6]
      a.must_be_instance_of WIN32OLE
      a.Count.must_equal 7
      7.times do |i|
        a.Get(i).must_equal i
      end
    end

    it '#array 1, 2, 3 ...' do
      a = array 0, 1, 2, 3, 4, 5, 6
      a.must_be_instance_of WIN32OLE
      a.Count.must_equal 7
      7.times do |i|
        a.Get(i).must_equal i
      end
    end
  end
end
