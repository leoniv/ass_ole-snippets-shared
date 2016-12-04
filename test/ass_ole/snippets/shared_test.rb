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
  end
end
