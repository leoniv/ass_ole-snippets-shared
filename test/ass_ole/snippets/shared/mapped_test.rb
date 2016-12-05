require 'test_helper'

module AssOle::Snippets::SharedTest
  describe AssOle::Snippets::Shared::Map do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#map {}' do
      hash_ = {1 => 1, 2 => 2, 3 => 3, 4 => 4}
      m = map hash_
      m.Count.must_equal 4
      hash_.each do |k, v|
        m.get(k).must_equal v
      end
    end

    it '#map **{}' do
      hash_ = {1 => 1, 2 => 2, 3 => 3, 4 => 4}
      m = map 1 => 1, 2 => 2, 3 => 3, 4 => 4
      m.Count.must_equal 4
      hash_.each do |k, v|
        m.get(k).must_equal v
      end
    end

    it '#map Symbol keys converts to String' do
      m = map one: 1, two: 2, three: 3
      m.get('one').must_equal 1
      m.get('two').must_equal 2
      m.get('three').must_equal 3
    end
  end

  describe AssOle::Snippets::Shared::Structure do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#structure Symbol keys converts to String' do
      s = structure one: 1, two: 2, three: 3
      s.send('one').must_equal 1
      s.send('two').must_equal 2
      s.send('three').must_equal 3
    end

    it "#structure {'one' => 1, 'two' => 2, 'three' => 3}" do
      hash_ = {'one' => 1, 'two' => 2, 'three' => 3}
      s = structure hash_
      s.Count.must_equal 3
      hash_.each do |k, v|
        s.send(k).must_equal v
      end
    end

    it "#structure 'one' => 1, 'two' => 2, 'three' => 3" do
      hash_ = {'one' => 1, 'two' => 2, 'three' => 3}
      s = structure 'one' => 1, 'two' => 2, 'three' => 3
      s.Count.must_equal 3
      hash_.each do |k, v|
        s.send(k).must_equal v
      end
    end

    it '#structure fail if invalid key' do
      e = proc {
        structure 'bad key' => 'value'
      }.must_raise WIN32OLERuntimeError
    end
  end
end
