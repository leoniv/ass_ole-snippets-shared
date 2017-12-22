require 'test_helper'

module AssOle::Snippets::SharedTest
  module InTransactionDo
    module Env
      extend AssLauncher::Api
      IB_TMPLT = File.join(FIXT_DIR, 'in_transaction_tmplt.cf')

      def self.make_ib(name)
        AssMaintainer::InfoBase.new(name,
          cs_file(file: File.join(Tmp::TMP_DIR, name)), false,
          platform_require: PLATFORM_REQUIRE,
          after_make: proc {|ib| ib.cfg.load(IB_TMPLT) && ib.db_cfg.update}).rebuild! :yes
      end

      IB0 = make_ib "in_transaction_do_test_0"
      IB1 = make_ib "in_transaction_do_test_1"
      IB2 = make_ib "in_transaction_do_test_2"
    end

    module Mixins
      module MakePerson
        def make_person(index = 0, additional_prop = nil, additional_prop_value = 'nil')
          result = cAtalogs.Persons.CreateItem
          result.Description = "fake person #{hash} #{index}"
          result.AdditionalProperties.Insert(additional_prop, additional_prop_value) if additional_prop
          result.Write
          result.Ref
        end
      end

      module OleRuntimeNew
        def ole_runtime_new(ib)
          Module.new do
            is_ole_runtime :external
            run ib
          end
        end
      end
    end

    describe AssOle::Snippets::Shared::InTransactionDo do
      extend Mixins::OleRuntimeNew
      like_ole_runtime ole_runtime_new(Env::IB0)
      include Mixins::MakePerson
      include desc

      before do
        ole_runtime_get.run Env::IB0
      end

      after do
        ole_runtime_get.stop
      end

      it 'manualy transaction control' do
        transactionActive.must_equal false
        _begin_transaction_
        transactionActive.must_equal true
        _commit_transaction_
        transactionActive.must_equal false

        transactionActive.must_equal false
        _begin_transaction_
        transactionActive.must_equal true
        _rollback_transaction_
        transactionActive.must_equal false
      end

      it 'in_transaction with managed_lock == true' do
        result = in_transaction(true, true) do
          :result
        end.must_equal :result
      end

      it 'in_transaction fail unless block_given?' do
        e = proc {
          in_transaction
        }.must_raise RuntimeError
        e.message.must_match %r{Block require}
      end

      it 'in_transaction must yields and returns block eval value' do
        yields = false
        result = in_transaction do
          yields = true
          :result
        end
        yields.must_equal true
        result.must_equal :result
      end

      it 'in_transaction transaction is active in block' do
        in_transaction do
          transactionActive
        end.must_equal true
      end

      it 'make multiple objects in transaction' do
        begin
          maked_db_objects = in_transaction do
            3.times.to_a.map do |i|
              make_person(i)
            end
          end

          maked_db_objects.each do |obj|
            obj.GetObject.wont_be_nil
          end
        ensure
          if maked_db_objects
            maked_db_objects.each do |obj|
              obj.GetObject.Delete if obj.GetObject
            end
          end
        end
      end

      it 'make multiple objects in rolledback transaction' do
        begin
          maked_db_objects = in_transaction(false) do
            3.times.to_a.map do |i|
              make_person(i)
            end
          end

          _rollback_transaction_

          maked_db_objects.each do |obj|
            obj.GetObject.must_be_nil
          end
        ensure
          if maked_db_objects
            maked_db_objects.each do |obj|
              obj.GetObject.Delete if obj.GetObject
            end
          end
        end
      end

      describe 'in_transaction with auto_commit' do
        it '==true (deafault) transaction commit after block executed' do
          begin
            result = in_transaction do
              make_person
            end
            transactionActive.must_equal false
            result.isEmpty.must_equal false
            result.GetObject.wont_be_nil
          ensure
            result.GetObject.Delete if result && result.GetObject
          end
        end

        describe '==false transaction allive after block executed' do
          it 'and then manualy rollBackTransaction' do
            begin
              result = in_transaction(false) do
                make_person
              end
              transactionActive.must_equal true
              result.isEmpty.must_equal false
              result.GetObject.wont_be_nil
              rollBackTransaction
              result.GetObject.must_be_nil
            ensure
              rollBackTransaction if transactionActive
            end
          end

          it 'and then manualy commitTransaction' do
            begin
              result = in_transaction(false) do
                make_person
              end
              transactionActive.must_equal true
              result.isEmpty.must_equal false
              result.GetObject.wont_be_nil
              commitTransaction
              result.GetObject.wont_be_nil
            ensure
              result.GetObject.Delete if result && result.GetObject
            end
          end
        end
      end

      describe 'in_transaction block with error on Ruby side' do
        it 'always rollBackTransaction and pop error' do
          person = nil
          begin
            e = proc {
              in_transaction do
                person = make_person
                person.GetObject.wont_be_nil
                fail 'error in block'
              end
            }.must_raise RuntimeError
            transactionActive.must_equal false
            person.GetObject.must_be_nil
            e.message.must_match %r{error in block}
          ensure
            person.GetObject.Delete if person && person.GetObject
          end
        end
      end

      describe 'make object with errors on the 1C side' do
        describe 'if transaction begin on Ruby side' do
          it 'if error raised in the OnWrite handler' do
            person = nil
            begin
              e = proc {
                person = in_transaction do
                  make_person(nil, 'Raise', 'Raise message')
                end
              }.must_raise WIN32OLERuntimeError
              transactionActive.must_equal false
              person.must_be_nil
              e.message.wont_match %r{Raise message}i, 'Fucking 1C'
              e.message.must_match %r{В данной транзакции уже происходили ошибки!}i, 'Fucking 1C'
            ensure
              person.GetObject.Delete if person && person.GetObject
            end
          end

          it 'if error raised after OnWrite handler' do
            person = nil
            begin
              e = proc {
                in_transaction do
                 person = make_person
                 person.GetObject.RaiseException('Raise message')
                end
              }.must_raise WIN32OLERuntimeError
              transactionActive.must_equal false
              person.GetObject.must_be_nil
              e.message.must_match %r{Raise message}i
            ensure
              person.GetObject.Delete if person && person.GetObject
            end
          end

          it 'if error disabled in the OnWrite handler' do
            person = nil
            begin
              person = in_transaction do
                make_person(nil, 'DisableRaised', 'Raise message')
              end
              transactionActive.must_equal false
              person.wont_be_nil
              person.GetObject.wont_be_nil
            ensure
              person.GetObject.Delete if person && person.GetObject
            end
          end

          it 'if Restrict setted in the OnWrite handler' do
            person = nil
            begin
              e = proc {
                person = in_transaction do
                  make_person(nil, 'Restrict')
                end
              }.must_raise WIN32OLERuntimeError
              transactionActive.must_equal false
              person.must_be_nil
              e.message.wont_match %r{Не удалось записать}i, 'Fucking 1C'
              e.message.must_match %r{В данной транзакции уже происходили ошибки!}i, 'Fucking 1C'
            ensure
              person.GetObject.Delete if person && person.GetObject
            end
          end
        end

        describe 'if transaction not begin on Ruby side' do
          it 'if error raised in the OnWrite handler' do
            person = nil
            begin
              e = proc {
                person = make_person(nil, 'Raise', 'Raise message')
              }.must_raise WIN32OLERuntimeError
              transactionActive.must_equal false
              person.must_be_nil
              e.message.must_match %r{Raise message}i
            ensure
              person.GetObject.Delete if person && person.GetObject
            end
          end

          it 'if Restrict setted in the OnWrite handler' do
            person = nil
            begin
              e = proc {
                person = make_person(nil, 'Restrict')
              }.must_raise WIN32OLERuntimeError
              transactionActive.must_equal false
              person.must_be_nil
              e.message.must_match %r{Не удалось записать}i
            ensure
              person.GetObject.Delete if person && person.GetObject
            end
          end
        end
      end
    end

    describe 'Nested #in_transaction' do
      include Mixins::OleRuntimeNew

      after do
        return unless @runtimed
        @runtimed.each do |r|
          r.ole_runtime_get.stop
        end
      end

      def runtimed
        @runtimed = 3.times.to_a.map do |i|
          runtime = ole_runtime_new eval "Env::IB#{i}"
          Class.new do
            like_ole_runtime runtime
            include AssOle::Snippets::Shared::InTransactionDo
            include Mixins::MakePerson
          end.new
        end
      end

      it 'in block yields correct worker' do
        workers = runtimed
        workers[0].in_transaction do |worker0|
          worker0.must_equal workers[0]
          workers[1].in_transaction do |worker1|
            worker0.must_equal workers[0]
            worker1.must_equal workers[1]
            workers[2].in_transaction do |worker2|
              worker0.must_equal workers[0]
              worker1.must_equal workers[1]
              worker2.must_equal workers[2]
            end
          end
        end
      end

      it 'in_transaction with auto_commit == false' do
        workers = runtimed
        begin
          workers[0].in_transaction(false) do |worker0|
            worker0.transactionactive.must_equal true
            workers[1].in_transaction(false) do |worker1|
              worker1.transactionactive.must_equal true
              workers[2].in_transaction(false) do |worker2|
                worker2.transactionactive.must_equal true
              end
            end
          end

          workers[0].transactionactive.must_equal true
          workers[1].transactionactive.must_equal true
          workers[2].transactionactive.must_equal true
        ensure
          workers.each do |w|
            w.rollbacktransaction if w.transactionactive
          end
        end
      end

      it 'in_transaction with auto_commit == true' do
        workers = runtimed
        begin
          workers[0].in_transaction do |worker0|
            worker0.transactionactive.must_equal true
            workers[1].in_transaction do |worker1|
              worker1.transactionactive.must_equal true
              workers[2].in_transaction do |worker2|
                worker2.transactionactive.must_equal true
              end
            end
          end

          workers[0].transactionactive.must_equal false
          workers[1].transactionactive.must_equal false
          workers[2].transactionactive.must_equal false
        ensure
          workers.each do |w|
            w.rollbacktransaction if w.transactionactive
          end
        end
      end

      describe 'make objects in transactions' do
        it 'auto_commit == true' do
          workers = runtimed
          maked_db_objects = [nil, nil, nil]
          begin
            workers[0].in_transaction do |worker0|
              maked_db_objects[0] = worker0.make_person(0)
              workers[1].in_transaction do |worker1|
                maked_db_objects[1] = worker1.make_person(1)
                maked_db_objects[2] = workers[2].in_transaction do |worker2|
                  worker2.make_person(2)
                end
              end
            end

            maked_db_objects[0].GetObject.wont_be_nil
            workers[0].sTring(maked_db_objects[0]).must_match %r{person}

            maked_db_objects[1].GetObject.wont_be_nil
            workers[1].sTring(maked_db_objects[1]).must_match %r{person}

            maked_db_objects[2].GetObject.wont_be_nil
            workers[2].sTring(maked_db_objects[2]).must_match %r{person}
          ensure
            maked_db_objects.each do |ref|
              ref.GetObject.Delete if ref && ref.GetObject
            end
          end
        end

        it 'auto_commit == false' do
          workers = runtimed
          maked_db_objects = [nil, nil, nil]
          begin
            workers[0].in_transaction(false) do |worker0|
              maked_db_objects[0] = worker0.make_person(0)
              workers[1].in_transaction(false) do |worker1|
                maked_db_objects[1] = worker1.make_person(1)
                maked_db_objects[2] = workers[2].in_transaction(false) do |worker2|
                  worker2.make_person(2)
                end
              end
            end

            maked_db_objects[0].Description.must_match %r{person}
            maked_db_objects[1].Description.must_match %r{person}
            maked_db_objects[2].Description.must_match %r{person}

            maked_db_objects[0].GetObject.wont_be_nil
            workers[0].sTring(maked_db_objects[0]).must_match %r{person}
            workers[0]._rollback_transaction_
            maked_db_objects[0].GetObject.must_be_nil

            maked_db_objects[1].GetObject.wont_be_nil
            workers[1].sTring(maked_db_objects[1]).must_match %r{person}
            workers[1]._commit_transaction_
            maked_db_objects[1].GetObject.wont_be_nil

            maked_db_objects[2].GetObject.wont_be_nil
            workers[2].sTring(maked_db_objects[2]).must_match %r{person}
            workers[2]._commit_transaction_
            maked_db_objects[2].GetObject.wont_be_nil
          ensure
            maked_db_objects.each do |ref|
              ref.GetObject.Delete if ref && ref.GetObject
            end
          end
        end

        it 'if error in second transaction' do
          workers = runtimed
          maked_db_objects = [nil, nil, nil]
          begin
            e = proc {
              workers[0].in_transaction do |worker0|
                maked_db_objects[0] = worker0.make_person(0)
                workers[1].in_transaction do |worker1|
                  maked_db_objects[1] = worker1.make_person(1)
                  maked_db_objects[2] = workers[2].in_transaction do |worker2|
                    worker2.make_person(2)
                  end
                  fail 'error in second transaction'
                end
              end
            }.must_raise RuntimeError
            e.message.must_match %r{error in second}

            maked_db_objects[0].GetObject.must_be_nil
            maked_db_objects[1].GetObject.must_be_nil
            maked_db_objects[2].GetObject.wont_be_nil
          ensure
            workers.each do |w|
              w.rollbacktransaction if w.transactionactive
            end
          end
        end
      end

      it 'if error in second transaction first and second rolledback but last transaction keep alive' do
        workers = runtimed
        begin
          e = proc {
            workers[0].in_transaction(false) do |worker0|
              workers[1].in_transaction(false) do |worker1|
                workers[2].in_transaction(false) do |worker2|
                end
                fail 'error in second transaction'
              end
            end
          }.must_raise RuntimeError
          e.message.must_match %r{error in second}

          workers[0].transactionactive.must_equal false
          workers[1].transactionactive.must_equal false
          workers[2].transactionactive.must_equal true
        ensure
          workers.each do |w|
            w.rollbacktransaction if w.transactionactive
          end
        end
      end
    end
  end
end
