require 'test_helper'

module AssOle::Snippets::SharedTest
  describe ::AssOle::Snippets::Shared::VERSION do
    it 'Not nil' do
      refute_nil ::AssOle::Snippets::Shared::VERSION
    end
  end

  describe AssOle::Snippets::Shared::Transaction do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#do_in_transaction' do
      do_in_transaction do
        transactionActive.must_equal true
        :return
      end.must_equal :return
    end

    it '#do_in_transaction fail if nested transaction' do
      beginTransAction
      e = proc {
        do_in_transaction {}
      }.must_raise RuntimeError
      e.message.must_match %r{Nested transaction is mindless in 1C runtime}
    end

    it 'fail in #do_in_transaction block' do
      e = proc {
        do_in_transaction do
          fail 'ERROR'
        end
      }.must_raise RuntimeError
      e.message.must_equal 'ERROR'
      transactionActive.must_equal false
    end

    after do
      rollBackTransaction if transactionActive
    end

    describe 'DEPRICATION message show' do
      it 'when included' do
        Kernel.expects(:warn).with(regexp_matches(%r{Transaction` is deprecated}i))
        Class.new do
          include AssOle::Snippets::Shared::Transaction
        end
      end

      it 'when extended' do
        Kernel.expects(:warn).with(regexp_matches(%r{Transaction` is deprecated}i))
        Module.new do
          extend AssOle::Snippets::Shared::Transaction
        end
      end

      it 'when #do_in_transaction call' do
        Kernel.expects(:warn).with(regexp_matches(%r{Transaction` is deprecated}i)).twice
        m = Module.new do
          extend AssOle::Snippets::Shared::Transaction
        end

        # Rescue RuntimeError
        e = proc {
          m.do_in_transaction
        }.must_raise ArgumentError
      end
    end
  end

  describe AssOle::Snippets::Shared::Query do
    like_ole_runtime EXT_RUNTIME
    include desc

    it '#query' do
      q = query('select &arg as arg', arg: 'value')
      q.execute.unload.get(0).arg.must_equal 'value'
      q.TempTablesManager.must_be_instance_of WIN32OLE
    end

    it '#temp_tables_manager' do
      temp_tables_manager.must_be_instance_of WIN32OLE
    end
  end

  describe AssOle::Snippets::Shared::XMLSerializer do
    require 'tempfile'
    # In external runtime TMP_IB.rm! fail '... /1Cv8.1CD (Errno::EBUSY)'
    # because external connection keep alive
    like_ole_runtime THICK_RUNTIME
    include desc

    attr_reader :xml_file
    before do
      @xml_file = Tempfile.new('xml')
      @xml_file.close
    end

    after do
      xml_file.unlink
    end

    it '#to_xml #from_xml' do
      from_xml(to_xml('value')).must_equal('value')
    end

    it '#to_xml_file #from_xml_file' do
      from_xml_file(to_xml_file('value', xml_file))
    end
  end
end
