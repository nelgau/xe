module Xe::Test
  module Helper
    module Enumerator
      # Invoked when this module is included in a test suite.
      def self.included(base)
        base.class_exec do
          # Context flags
          let(:enabled) { true }
          let(:tracing) { false }

          let(:count)      { 6 }
          let(:enumerable) { (0...count).to_a }
          let(:deferrable) { Xe::Deferrable.new }

          let(:context_options) { { enabled: enabled, tracing: tracing } }
          let(:finalize_proc)   { Proc.new { raise Xe::Test::Error } }
        end
      end

      def each_index(&blk)
        (0...enumerable.length).each(&blk)
      end

      # Contexts

      # Memoized reference to a mock context. Can be overriden below.
      def context
        @context ||= new_context_mock(context_options, &finalize_proc)
      end

      # Wraps execution in a new context mock.
      def with_context_mock(options={}, &finalize_proc)
        all_options = context_options.merge(options)
        @context = new_context_mock(all_options, &finalize_proc)
        yield
      ensure
        @context = nil
      end

      # Set the strict expectation of no concurrency.
      def expect_serial!
        expect(context).to_not receive(:finalize!)
        expect(context).to_not receive(:begin_fiber)
        expect(context).to_not receive(:dispatch)
        expect(context).to_not receive(:proxy)
      end

      # Waiting and Dispatching

      def target_for_index(index)
        Xe::Target.new(deferrable, index, 0)
      end

      def wait_for_index(index)
        context.wait(target_for_index(index))
      end

      def proxy_for_index(index, &force_proc)
        target = target_for_index(index)
        context.proxy(target, &force_proc)
      end

      def dispatch_for_index(index)
        target = target_for_index(index)
        context.dispatch(target, index)
      end

      def release_enumerable_waiters
        each_index do |index|
          dispatch_for_index(index)
        end
      end
    end
  end
end
