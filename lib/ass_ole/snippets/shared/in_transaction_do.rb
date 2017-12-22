module AssOle
  module Snippets
    module Shared
      # Mixin for wrapping execution into 1C transaction.
      # @example
      #   #!/sbin/env ruby
      #
      #   require 'ass_ole'
      #   require 'ass_ole/snippets/shred/in_transaction_do'
      #
      #   PLATFORM_REQUIRE = '~> 8.3.10.0'
      #
      #   # External connection runtime for accounting infobase
      #   module AccountingRuntime
      #     is_ole_runtime :external
      #   end
      #
      #   # External connection runtime for HRM infobase
      #   module HrmRuntime
      #     is_ole_runtime :external
      #   end
      #
      #   # Worker do anything in accounting infobase
      #   class AcctWorker
      #     like_ole_runtime AccountingRuntime
      #     include AssOle::Snipptes::Shared::InTransactionDo
      #
      #     attr_reader :ib
      #     def initialize(connection_string)
      #       @ib = AssMaintainer::InfoBase
      #         .new('accounting', connection_string, PLATFORM_REQUIRE)
      #       ole_runtime_get.run ib #connect to infobase
      #     end
      #
      #     def action_one
      #       #NOP
      #     end
      #
      #     def action_two(action_one_result)
      #       #NOP
      #     end
      #
      #     def make_job_in_transaction
      #       in_transaction do
      #         make_job
      #       end
      #     end
      #
      #     def make_job
      #       action_two(action_one)
      #     end
      #   end
      #
      #   # Worker do anything in HRM infobase
      #   class HrmWorker
      #     like_ole_runtime HrmRuntime
      #     include AssOle::Snipptes::Shared::InTransactionDo
      #
      #     attr_reader :ib
      #     def initialize(connection_string)
      #       @ib = AssMaintainer::InfoBase
      #         .new('accounting', connection_string, PLATFORM_REQUIRE)
      #       ole_runtime_get.run ib #connect to infobase
      #     end
      #
      #     def action_one(acct_result)
      #       #NOP
      #     end
      #
      #     def action_two(acct_result)
      #       #NOP
      #     end
      #
      #     def make_job(acct_result)
      #       action_one(acct_result)
      #       action_two(acct_reult)
      #       true
      #     end
      #   end
      #
      #   module Programm
      #     # It working like distributed transaction
      #     def self.execute_in_nested_transaction(acct_cs, hrm_cs)
      #       # Trasaction in HrmWorker committed  automatically
      #       HrmWorker.new(hrm_cs).in_transaction do |hrm_worker|
      #         # Trasaction in AcctWorker keep alive
      #         acct_result = AcctWorker.new(acct_cs).in_transaction(false) do |acct_worker|
      #           acct_worker.make_job
      #         end
      #         result = hrm_worker.make_job(acct_result)
      #         #Commit AcctWorker transaction
      #         acct_worker._commit_transaction_
      #         result
      #       end
      #     end
      #   end
      #
      #   #Do in accounting infobase only
      #   puts AcctWorker.new(ARGV[0]).make_job_in_transaction
      #
      #   #Do in accounting and hrm infobases
      #   puts Programm.execute_in_nested_transaction(ARGV[0], ARGV[1])
      module InTransactionDo
        is_ole_snippet

        # Wrap execution in 1C transaction. If execution failure
        # transaction always rolledback!
        # @param auto_commit [true false] if +true+ transaction will be committed
        #  automatically
        # @param managed_lock (see #_begin_transaction_)
        # @yield self
        # @return execution result
        def in_transaction(auto_commit = true, managed_lock = false, &block)
          fail 'Block require' unless block_given?
          _begin_transaction_ managed_lock
          begin
            result = yield self
            _commit_transaction_ if auto_commit
          rescue Exception => e
            _rollback_transaction_
            fail e
          end
          result
        end

        # @param managed_lock [false true] if true 1C +BeginTransaction+ call with
        #  +DataLockControlMode.Managed+
        def _begin_transaction_(managed_lock = false)
          ole_connector.beginTransaction unless managed_lock
          ole_connector.beginTransaction ole_connector
            .dataLockControlMode.Managed if managed_lock
        end

        def _rollback_transaction_
          ole_connector.rollBackTransaction
        end

        def _commit_transaction_
          ole_connector.commitTransaction
        end
      end
    end
  end
end
