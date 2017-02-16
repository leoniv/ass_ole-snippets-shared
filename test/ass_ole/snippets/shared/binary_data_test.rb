require 'test_helper'

module AssOle::Snippets::SharedTest
  describe AssOle::Snippets::Shared::BinaryData do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#binary_data && #binary_data_get' do
      ole_bin = binary_data('data')
      ole_bin.must_be_instance_of WIN32OLE
      binary_data_get(ole_bin).must_equal 'data'
    end

    it '#binary_data mocked' do
      seq = sequence('binary_data')
      temp_file = mock

      AssOle::Snippets::Shared::BinaryData::TempFile\
        .expects(:new).with(:data).returns(temp_file)

      temp_file.expects(:write).in_sequence(seq)
      temp_file.expects(:win_path).returns(:win_path)

      self.expects(:newObject).with('BinaryData', :win_path)
        .returns(:binary_data)

      temp_file.expects(:rm!).in_sequence(seq)

      binary_data(:data).must_equal :binary_data
    end
  end

  describe AssOle::Snippets::Shared::BinaryData::TempFile do
    after do
      rm_tem_file
    end

    def rm_tem_file
      if @temp_file
        temp_file.rm!
      end
    end

    def temp_file(data = 'data')
      @temp_file ||= self.class.desc.new(data)
    end

    it '#win_path smoky' do
      temp_file.win_path.must_match %r{\\}
    end

    it '#win_path mocked' do
      temp_file.expects(:real_win_path).with(temp_file.path).returns(:win_path)
      temp_file.win_path.must_equal :win_path
    end

    it '#rm!' do
      File.exist?(temp_file.path).must_equal true
      temp_file.rm!
      temp_file.path.must_be_nil
    end

    it '#temp_file' do
      temp_file.temp_file.class.must_equal Tempfile
    end
  end
end
