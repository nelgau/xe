require 'spec_helper'
require 'set'

describe Xe::Context do
  include Xe::Test::Mock::Context

  subject { Xe::Context.new(options) }

  before do
    Xe.config.stub(:context_options) { config_context_options }
  end

  let(:options) { {
    :enabled => true,
    :max_fibers => 20,
    :tracer => tracer
  } }

  let(:tracer) { Xe::Tracer::Base.new }
  let(:config_context_options) { {} }

  let(:realizers) do
    (0...5).map do |i|
      new_realizer_mock(i)
    end
  end

  let(:deferrable) { realizers[0] }
  let(:id)         { 0 }
  let(:group_key)  { 1 }

  let(:target)     { Xe::Target.new(deferrable, id, group_key) }

  describe '.wrap' do

    subject { Xe::Context }

    context "when no block is given" do
      it "is a no-op" do
        subject.wrap
      end
    end

    context "when there is a current context" do
      before do
        subject.current = Xe::Context.new
      end

      after do
        subject.clear_current
      end

      it "yields with the context" do
        context = subject.current
        expect { |b| subject.wrap(&b) }.to yield_with_args(context)
      end

      it "returns the result of the block" do
        expect(subject.wrap { 2 }).to eq(2)
      end
    end

    context "when there is no current context" do
      before do
        subject.clear_current
      end

      it "yields with an instance of Xe::Context" do
        captured_context = nil
        subject.wrap { |c| captured_context = c }
        expect(captured_context).to be_an_instance_of(Xe::Context)
      end

      it "clears the context afterwards" do
        subject.wrap { |c| }
        expect(subject.current).to be_nil
      end

      context "when options are given" do
        let(:new_options) { { :foo => :toot } }

        it "constructs a context with the given options" do
          captured_context = nil
          subject.wrap(new_options) { |c| captured_context = c }
          expect(captured_context.options).to eq(new_options)
        end
      end

      it "finalizes the context" do
        subject.wrap do |context|
          expect(context).to receive(:finalize!).and_call_original
        end
      end

      it "asserts that the context is vacant" do
        subject.wrap do |context|
          expect(context).to receive(:assert_vacant!).and_call_original
        end
      end

      it "invalidates the context" do
        subject.wrap do |context|
          expect(context).to receive(:invalidate!).and_call_original
        end
      end

      context "when the block raises an exception" do
        def invoke(&blk)
          subject.wrap do |context|
            blk.call(context) if block_given?
            raise Xe::Test::Error
          end
        end

        it "raises" do
          expect { invoke }.to raise_error(Xe::Test::Error)
        end

        it "clears the context afterwards" do
          expect { invoke }.to raise_error(Xe::Test::Error)
          expect(subject.current).to be_nil
        end

        it "invalidates the context" do
          expect {
            invoke do |context|
              expect(context).to receive(:invalidate!).and_call_original
            end
          }.to raise_error(Xe::Test::Error)
        end
      end
    end

    context "when wrapping twice" do
      it "yields the same context" do
        captured_context1 = nil
        captured_context2 = nil

        subject.wrap do |c1|
          captured_context1 = c1
          subject.wrap do |c2|
            captured_context2 = c2
          end
        end

        expect(captured_context1).to eq(captured_context2)
      end
    end

  end

  describe '.exists?' do

    subject { Xe::Context }

    context "when there is no current context" do
      before do
        subject.clear_current
      end

      it "is false" do
        expect(subject.exists?).to be_false
      end
    end

    context "when there is a current context" do
      before do
        subject.current = Xe::Context.new
      end

      after do
        subject.clear_current
      end

      it "is true" do
        expect(subject.exists?).to be_true
      end
    end

  end

  describe '.active?' do

    subject { Xe::Context }

    context "when there is no current context" do
      before do
        subject.clear_current
      end

      it "is false" do
        expect(subject.active?).to be_false
      end
    end

    context "when there is a current context (disabled)" do
      before do
        subject.current = Xe::Context.new(:enabled => false)
      end

      after do
        subject.clear_current
      end

      it "is true" do
        expect(subject.active?).to be_false
      end
    end

    context "when there is a current context (enabled)" do
      before do
        subject.current = Xe::Context.new(:enabled => true)
      end

      after do
        subject.clear_current
      end

      it "is true" do
        expect(subject.active?).to be_true
      end
    end

  end

  describe '#initialize' do

    # Clear out any options set above.
    let(:options) { {} }
    let(:config_context_options) { { :foo => :bar } }

    context "when no options are given" do
      it "sets the options from the global config" do
        expect(subject.options).to eq(config_context_options)
      end
    end

    context "when options are given" do
      let(:options) { { :baz => :woo } }

      it "sets the options by merging with the global config" do
        expect(subject.options).to eq({
          :foo => :bar,
          :baz => :woo
        })
      end

      context "when the options collide" do
        let(:options) { { :foo => :hey } }

        it "prefers the options passed to the initializer" do
          expect(subject.options).to eq({ :foo => :hey })
        end
      end
    end

    # In the tests that follow, we assume that the global config has no effect
    # due to it being stubbed above.

    it "disables the context" do
      expect(subject).to_not be_enabled
    end

    context "when the enabled option is true" do
      before do
        options.merge!(:enabled => true)
      end

      it "enables the context" do
        expect(subject).to be_enabled
      end
    end

    it "sets the max_fibers attribute to 1" do
      expect(subject.max_fibers).to eq(1)
    end

    context "when the max_fibers option is given" do
      let(:max_fibers) { 10 }

      before do
        options.merge!(:max_fibers => max_fibers)
      end

      it "sets the max_fibers attribute to the value in the option" do
        expect(subject.max_fibers).to eq(max_fibers)
      end
    end

    it "sets the tracer attribute to nil" do
      expect(subject.tracer).to be_nil
    end

    context "when the tracer options is given" do
      before do
        options.merge!(:tracer => tracer)
      end

      it "sets the tracer attribute to the given" do
        expect(subject.tracer).to eq(tracer)
      end

      context "when the tracer option is ':stdout'" do
        before do
          options.merge!(:tracer => :stdout)
        end

        it "sets the tracer attribute to be an instance of Xe::Tracer::Text" do
          expect(subject.tracer).to be_an_instance_of(Xe::Tracer::Text)
        end
      end
    end

    it "sets the policy attribute to be an instance of Xe::Policy::Default" do
      expect(subject.policy).to be_an_instance_of(Xe::Policy::Default)
    end

    context "when the policy option is given" do
      let(:policy) { double(Xe::Policy::Base) }

      before do
        options.merge!(:policy => policy)
      end

      it "sets the policy attribute to the given" do
        expect(subject.policy).to eq(policy)
      end
    end

    it "sets the loom attribute to be an instance of Xe::Loom::Default" do
      expect(subject.loom).to be_an_instance_of(Xe::Loom::Default)
    end

    context "when the loom option is given" do
      let(:loom) { double(Xe::Loom::Base) }

      before do
        options.merge!(:loom => loom)
      end

      it "sets the loom attribute to the given" do
        expect(subject.loom).to eq(loom)
      end
    end

    it "sets the scheduler attribute to an instance of Xe::Context::Scheduler" do
      expect(subject.scheduler).to be_an_instance_of(Xe::Context::Scheduler)
    end

    it "uses the policy to initialize the scheduler" do
      expect(subject.scheduler.policy).to eq(subject.policy)
    end

    it "sets the proxies attribute to an empty hash" do
      expect(subject.proxies).to be_an_instance_of(Hash)
      expect(subject.proxies).to be_empty
    end

    it "sets the cache attribute to an empty hash" do
      expect(subject.cache).to be_an_instance_of(Hash)
      expect(subject.cache).to be_empty
    end

  end

  describe '#enum' do

    let(:enumerable) { [1, 2, 3] }
    let(:enum_options) { {} }

    def new_enumerator
      subject.enum(enumerable, enum_options)
    end

    it "returns an instance of Xe::Enumerator" do
      expect(new_enumerator).to be_an_instance_of(Xe::Enumerator)
    end

    it "returns an enumerator for the context" do
      expect(new_enumerator.context).to eq(subject)
    end

    it "returns an enumerator for the enumerable" do
      expect(new_enumerator.enumerable).to eql(enumerable)
    end

    context "when enumerator options are given" do
      let(:enum_options) { { :foo => :bar } }

      it "returns an enumerator with the options" do
        expect(new_enumerator.options).to eq(enum_options)
      end
    end

  end

  describe '#finalize!' do

    context "when there are no events in the scheduler" do
      it "is a no-op" do
        subject.finalize!
      end
    end

    context "when a tracer is enabled" do
      it "emits 'finalize_start'" do
        expect(tracer).to receive(:finalize_start)
        subject.finalize!
      end
    end

    context "when values has been deferred" do
      attr_reader :proxies

      let(:deferrals) { [
        [realizers[0], 0, 'a'],
        [realizers[0], 1, 'a'],
        [realizers[1], 2, 'b']
      ]}

      let(:realizations) { {
        realizers[0] => [[[0, 1], 'a']],
        realizers[1] => [[[   2], 'b']]
      } }

      let(:values) do
        deferrals.map do |(realizer, id, group_key)|
          realizer.value_for_id(id)
        end
      end

      before do
        @proxies = deferrals.map do |(realizer, id, group_key)|
          subject.defer(realizer, id, group_key)
        end
      end

      it "dequeues all events from the scheduler" do
        subject.finalize!
        expect(subject.scheduler).to be_empty
      end

      it "calls the realizers" do
        subject.finalize!
        realizations.each do |realizer, performs|
          expect(realizer.performs).to eq(performs)
        end
      end

      it "resolves the proxies" do
        subject.finalize!
        proxies.zip(values).each do |(proxy, value)|
          expect(proxy.__subject).to eq(value)
        end
      end

      context "when a fiber is waiting" do
        let(:out) { {} }

        before do
          subject.begin_fiber do
            # Invoke a method on the proxy to start waiting.
            out[:value] = subject.defer(realizers[2], 0, 'a').to_i
          end
        end

        it "releases the fiber" do
          subject.finalize!
          value = realizers[2].value_for_id(0)
          expect(out[:value]).to eq(value)
        end
      end

      context "when a value is deferred during finalization" do
        let(:out) { {} }

        before do
          subject.begin_fiber do
            # Invoke a method on the proxy to start waiting.
            subject.defer(realizers[2], 0, 'a').to_i
            out[:proxy] = subject.defer(realizers[3], 8, 'c')
          end
        end

        it "calls the realizer for that value" do
          subject.finalize!
          expect(realizers[3].performs).to eq([[[8], 'c']])
        end

        it "resolves the proxies for that value" do
          subject.finalize!
          value = realizers[3].value_for_id(8)
          expect(out[:proxy].__subject).to eq(value)
        end
      end

      it "emits 'finalize_step' for each event" do
        events = subject.scheduler.events.values
        captured_events = []
        tracer.stub(:finalize_step) do |event|
          captured_events << event
        end
        subject.finalize!
        events.each do |event|
          expect(captured_events).to include(event)
        end
      end
    end

    context "when a fiber is waiting and never released" do
      let(:source) { Xe::Deferrable.new }
      let(:target) { Xe::Target.new(source) }

      before do
        subject.begin_fiber do
          subject.wait(target) do
            # This should never happen.
            raise Xe::Text::Error
          end
        end
      end

      it "raises Xe::DeadlockError" do
        expect { subject.finalize! }.to raise_error(Xe::DeadlockError)
      end

      it "emits 'finalize_deadlock'" do
        expect(tracer).to receive(:finalize_deadlock)
        expect { subject.finalize! }.to raise_error(Xe::DeadlockError)
      end
    end

  end

  describe '#assert_vacant!' do

    context "When the context is vacant" do
      it "does not raise" do
        subject.assert_vacant!
      end
    end

    context "when there are events in the scheduler" do
      before do
        subject.defer(realizers[0], 0, 'a')
      end

      it "raises Xe::InconsistentContextError" do
        expect {
          subject.assert_vacant!
        }.to raise_error(Xe::InconsistentContextError)
      end
    end

    context "when there are running fibers" do
      before do
        # Leave this fiber running by yielding.
        @fiber = subject.begin_fiber { ::Fiber.yield }
      end

      it "raises Xe::InconsistentContextError" do
        expect {
          subject.assert_vacant!
        }.to raise_error(Xe::InconsistentContextError)
      end
    end

    context "when there are waiting fibers" do
      before do
        subject.begin_fiber do
          # Invoke a method on the proxy to start waiting.
          subject.defer(realizers[0], 0, 'a').to_i
        end
      end

      it "raises Xe::InconsistentContextError" do
        expect {
          subject.assert_vacant!
        }.to raise_error(Xe::InconsistentContextError)
      end
    end

  end

  describe '#enabled?' do
    let(:enabled) { true }

    before do
      options.merge!(:enabled => enabled)
    end

    context "when the context is enabled" do
      let(:enabled) { true }

      it "is true" do
        expect(subject).to be_enabled
      end
    end

    context "when the context is disabled" do
      let(:enabled) { false }

      it "is false" do
        expect(subject).to_not be_enabled
      end
    end
  end

  describe '#valid?' do

    context "before invalidation" do
      it "is true" do
        expect(subject).to be_valid
      end
    end

    context "after invalidation" do
      it "is false" do
        subject.invalidate!
        expect(subject).to_not be_valid
      end
    end

  end

  describe '#invalidate!' do

    it "marks the context as no longer valid" do
      subject.invalidate!
      expect(subject).to_not be_valid
    end

    context "when there are outstanding proxies" do
      before do
        @proxies = realizers.map do |realizer|
          subject.defer(realizer, 0, 'a')
        end
      end

      it "invalidates the proxies" do
        subject.invalidate!
        @proxies.each do |proxy|
          expect(proxy.__valid?).to be_false
        end
      end
    end

    context "when there are waiting fibers" do
      let(:fiber_count) { 2 }

      before do
        @fibers = (0...fiber_count).map do |i|
          subject.begin_fiber do
            subject.wait(target) do
              # This should never happen.
              raise Xe::Test::Error
            end
          end
        end
      end

      it "releases all fibers" do
        subject.release_all_fibers!
        @fibers.each { |f| expect(f).to_not be_alive }
      end
    end

    it "sets the policy to nil" do
      subject.invalidate!
      expect(subject.policy).to be_nil
    end

    it "sets the loom to nil" do
      subject.invalidate!
      expect(subject.loom).to be_nil
    end

    it "sets the scheduler to nil" do
      subject.invalidate!
      expect(subject.scheduler).to be_nil
    end

    it "sets the proxies to nil" do
      subject.invalidate!
      expect(subject.proxies).to be_nil
    end

    it "sets the cache to nil" do
      subject.invalidate!
      expect(subject.cache).to be_nil
    end

  end

  describe '#defer' do

    def invoke
      subject.defer(deferrable, id, group_key)
    end

    context "when the context is invalid" do
      before do
        subject.invalidate!
      end

      it "raises Xe::DeferError" do
        expect { invoke }.to raise_error(Xe::DeferError)
      end
    end

    it "emits 'value_deferred' with a target" do
      captured_target = nil
      expect(tracer).to receive(:value_deferred) { |t| captured_target = t }
      invoke
      expect(captured_target).to eq(target)
    end

    it "adds the target to the scheduler" do
      invoke
      event = subject.scheduler.pop_event(target)
      expect(event).to_not be_nil
      expect(event.deferrable).to eq(deferrable)
      expect(event.group_key).to eq(group_key)
      expect(event.group).to include(id)
    end

    it "returns an instance of Xe::Proxy" do
      expect(Xe::Proxy.proxy?(invoke)).to be_true
    end

    it "returns a valid proxy" do
      expect(invoke.__valid?).to be_true
    end

    it "returns an unresolved proxy" do
      expect(invoke.__resolved?).to be_false
    end

    context "when realizing the value in an unmanaged fiber" do
      before do
        @proxy = invoke
      end

      it "invokes realize_target on the context" do
        expect(subject).to receive(:realize_target).with(target)
        @proxy.to_i
      end

      it "realizes the value" do
        expect(@proxy.to_i).to eq(realizers[0].value_for_id(id))
      end
    end

    context "when realizing the value in a managed fiber" do
      before do
        @proxy = invoke
      end

      it "suspends the execution of the fiber" do
        fiber = subject.begin_fiber { @proxy.to_i }
        expect(fiber).to be_alive
      end

      it "adds the fiber to the waiters on the target" do
        fiber = subject.begin_fiber { @proxy.to_i }
        expect(subject.loom.waiters[target]).to eq([fiber])
      end
    end

    context "when the target is cached from a previous realization" do
      before do
        invoke.to_i
      end

      it "has a cached value" do
        expect(subject.cache[target]).to_not be_nil
      end

      it "is not a proxy" do
        expect(Xe::Proxy.proxy?(invoke)).to be_false
      end

      it "has the correct value" do
        expect(invoke.to_i).to eq(realizers[0].value_for_id(id))
      end

      it "doesn't add the target to the scheduler" do
        invoke
        event = subject.scheduler.pop_event(target)
        expect(event).to be_nil
      end

      it "emits 'value_cached' with a target" do
        captured_target = nil
        expect(tracer).to receive(:value_cached) { |t| captured_target = t }
        invoke
        expect(captured_target).to eq(target)
      end
    end

  end

  describe '#dispatch' do

    let(:value) { 2 }

    def invoke
      subject.dispatch(target, value)
    end

    it "emits 'value_dispatched' with a target" do
      captured_target = nil
      expect(tracer).to receive(:value_dispatched) { |t| captured_target = t }
      invoke
      expect(captured_target).to eq(target)
    end

    context "when there are unresolved proxies" do
      before do
        @proxy = subject.proxy(target) do
          # This should never happen.
          raise Xe::Test::Error
        end
      end

      it "sets the proxy's subject" do
        invoke
        expect(@proxy.__subject).to eq(2)
      end

      it "resolves the proxy as a value" do
        invoke
        expect(@proxy.__value?).to be_true
      end

      it "invalidates the proxy" do
        invoke
        expect(@proxy.__valid?).to be_false
      end
    end

    context "when there are waiting fibers" do
      let(:out) { {} }

      before do
        subject.begin_fiber do
          out[:value] = subject.wait(target) do
            # This should never happen.
            raise Xe::Test::Error
          end
        end
      end

      it "releases the fibers with the value" do
        invoke
        expect(out[:value]).to eq(value)
      end

      it "release all fibers for the target" do
        invoke
        expect(subject.loom.waiter_count(target)).to eq(0)
      end
    end

  end

  describe '#proxy' do

    def invoke(&force_proc)
      subject.proxy(target, &force_proc)
    end

    it "returns a proxy" do
      expect(Xe::Proxy.proxy?(invoke)).to be_true
    end

    it "adds the proxy to the context" do
      proxy = invoke
      expect(subject.proxies[target][0]).to eql(proxy)
    end

    it "emits 'proxy_new' with a target" do
      captured_target = nil
      expect(tracer).to receive(:proxy_new) { |t| captured_target = t }
      invoke
      expect(captured_target).to eq(target)
    end

    context "when resolving the subject in an unmanaged fiber" do
      it "calls force_proc" do
        did_call = false
        proxy = invoke { did_call = true; 3 }
        proxy.to_i
        expect(did_call).to be_true
      end

      it "sets the proxies subject to the return value of force_proc" do
        proxy = invoke { 3 }
        proxy.to_i
        expect(proxy.__subject).to eq(3)
      end
    end

    context "when resolving the subject in a managed fiber" do

      before do
        @proxy = invoke do
          # This should never happen.
          raise Xe::Test::Error
        end
      end

      it "adds the fiber to the waiters for that target" do
        fiber = subject.begin_fiber { @proxy.to_i }
        expect(subject.loom.waiters[target]).to eq([fiber])
      end
    end

  end

  describe '#begin_fiber' do

    def invoke(&blk)
      subject.begin_fiber(&blk)
    end

    def invoke_suspended
      subject.begin_fiber { ::Fiber.yield }
    end

    context "when there are available fibers" do
      before do
        options.merge!(:max_fibers => nil)
      end

      it "returns an instance of Xe::Loom::Fiber" do
        fiber = invoke_suspended
        expect(fiber).to be_an_instance_of(Xe::Loom::Fiber)
      end

      it "starts execution in the proc" do
        did_call = false
        fiber = invoke { did_call = true }
        expect(did_call).to be_true
      end

      it "emits 'fiber_new'" do
        expect(tracer).to receive(:fiber_new)
        invoke_suspended
      end
    end

    context "when no fibers are avaiable" do
      let(:max_fibers) { 2 }

      before do
        options.merge!(:max_fibers => max_fibers)
      end

      context "but can be freed" do
        before do
          @fibers = (0...max_fibers).map do |i|
            invoke { subject.defer(deferrable, i, 'a').to_i }
          end
        end

        it "invokes #free_fibers" do
          expect(subject).to receive(:free_fibers).and_call_original
          invoke_suspended
        end

        it "returns an instance of Xe::Loom::Fiber" do
          fiber = invoke_suspended
          expect(fiber).to be_an_instance_of(Xe::Loom::Fiber)
        end

        it "starts execution in the proc" do
          did_call = false
          fiber = invoke { did_call = true }
          expect(did_call).to be_true
        end

        it "emits 'fiber_new'" do
          expect(tracer).to receive(:fiber_new)
          invoke_suspended
        end
      end

      context "and none can be freed" do
        before do
          @fibers = (0...max_fibers).map do |i|
            invoke_suspended
          end
        end

        it "raises Xe::DeadlockError" do
          expect { invoke_suspended }.to raise_error(Xe::DeadlockError)
        end
      end
    end

  end

  describe '#free_fibers' do
    let(:max_fibers) { 2 }

    before do
      options.merge!(:max_fibers => max_fibers)
    end

    context "when there are no events in the scheduler" do
      it "is a no-op" do
        subject.free_fibers
      end
    end

    context "when there are events in the scheduler" do
      let(:realizations) { [
        [(0...max_fibers).to_a, 'a']
      ] }

      before do
        # These should be realized by a single event.
        @fibers = (0...max_fibers).map do |i|
          subject.begin_fiber { subject.defer(deferrable, i, 'a').to_i }
        end
      end

      it "realizes events" do
        expect(subject).to receive(:realize_event).and_call_original
        subject.free_fibers
      end

      it "calls the realizers" do
        subject.free_fibers
        expect(deferrable.performs).to eq(realizations)
      end

      it "frees fibers" do
        subject.free_fibers
        expect(subject.can_begin_fiber?).to be_true
      end

      it "emits 'fiber_free' for each event" do
        event = subject.scheduler.events.values.flatten.first
        expect(tracer).to receive(:fiber_free).with(event)
        subject.free_fibers
      end
    end

    context "when the fibers cannot be freed" do
      before do
        @fibers = (0...max_fibers).map do |i|
          subject.begin_fiber { ::Fiber.yield }
        end
      end

      it "raises Xe::DeadlockError" do
        expect { subject.free_fibers }.to raise_error
      end
    end

  end

  describe '#can_begin_fiber?' do

    context "when the max_fibers attribute is nil" do
      before do
        options.merge!(:max_fibers => nil)
      end

      it "is true" do
        expect(subject.can_begin_fiber?).to be_true
      end
    end

    context "when the max_fibers attribute is finite" do
      let(:max_fibers) { 2 }

      before do
        options.merge!(:max_fibers => max_fibers)
      end

      it "is true" do
        expect(subject.can_begin_fiber?).to be_true
      end

      context "when the supply of fibers is exhausted" do
        before do
          @fibers = (0...max_fibers).map do |i|
            subject.begin_fiber { ::Fiber.yield }
          end
        end

        it "is false" do
          expect(subject.can_begin_fiber?).to be_false
        end
      end

    end

  end

  describe '#realize_target' do

    def invoke
      subject.realize_target(target)
    end

    context "when the target doesn't refer to an event in the scheduler" do
      it "raises Xe::InconsistentContextError" do
        expect { invoke }.to raise_error(Xe::InconsistentContextError)
      end
    end

    context "when the target refers to an event in the scheduler" do
      before do
        # Two events.
        @proxy1 = subject.defer(*target.to_a)
        @proxy2 = subject.defer(realizers[1], 1, 'b')
      end

      it "realizes the referenced event" do
        event_key = Xe::Event.target_key(target)
        event = subject.scheduler.events[event_key]
        subject.should_receive(:realize_event).with(event).and_call_original
        invoke
      end

      it "resolves the proxy" do
        invoke
        expect(@proxy1.__resolved?).to be_true
      end

      it "removes the event from the scheduler" do
        invoke
        expect(subject.scheduler.events[target]).to be_nil
      end
    end

  end

  describe '#realize_event' do

    let(:proxy_count) { 10 }

    before do
      # These should be realized by a single event.
      @proxies = (0...proxy_count).map do |i|
        subject.defer(deferrable, i, 'a')
      end
      # Namely, this one...
      @event = subject.scheduler.events.values.flatten.first
    end

    def invoke
      subject.realize_event(@event)
    end

    it "returns a hash of realized values (by id)" do
      results = invoke
      (0...proxy_count).each do |i|
        value = deferrable.value_for_id(i)
        expect(results[i]).to eq(value)
      end
    end

    it "dispatches values" do
      dispatched_values = {}
      subject.stub(:dispatch) { |t, v| dispatched_values[t] = v }
      invoke
      @event.targets.each do |t|
        value = deferrable.value_for_id(t.id)
        expect(dispatched_values[t]).to eq(value)
      end
    end

    it "caches values" do
      invoke
      @event.targets.each do |t|
        value = deferrable.value_for_id(t.id)
        expect(subject.cache[t]).to eq(value)
      end
    end

    it "resolves the proxies" do
      invoke
      @proxies.each do |proxy|
        expect(proxy.__resolved?).to be_true
      end
    end

    it "emits 'event_realize' with the event" do
      expect(tracer).to receive(:event_realize).with(@event)
      invoke
    end

    it "emits 'value_realized' with each target" do
      emitted_targets = []
      tracer.stub(:value_realized) { |t| emitted_targets << t }
      invoke
      expect(emitted_targets).to eq(@event.targets)
    end

  end

  describe '#wait' do

    context "when invoked outside of a managed fiber" do
      it "yields to cantwait_proc" do
        did_call = false
        subject.wait(target) { did_call = true }
        expect(did_call).to eq(true)
      end
    end

    context "when invoked inside of a managed fiber" do
      let(:out) { {} }

      def invoke
        subject.begin_fiber do
          out[:value] = subject.wait(target) do
            # This should never happen.
            raise Xe::Test::Error
          end
        end
      end

      it "yields control" do
        fiber = invoke
        expect(fiber).to be_alive
      end

      it "adds the fiber to waiters for the target" do
        fiber = invoke
        expect(subject.loom.waiters[target]).to eq([fiber])
      end

      it "emits 'fiber_wait' with the target" do
        expect(tracer).to receive(:fiber_wait).with(target)
        invoke
      end
    end

  end

  describe '#release' do

    let(:value) { 5 }
    let(:fiber_count) { 10 }

    def invoke
      subject.release(target, value)
    end

    context "when no fibers are waiting on the target" do
      it "is a no-op" do
        subject.release(target, value)
      end
    end

    context "when fibers are waiting on the target" do
      let(:out) { {} }

      before do
        @fibers = (0...fiber_count).map do |i|
          subject.begin_fiber do
            out[i] = subject.wait(target) do
              # This should never happen.
              raise Xe::Test::Error
            end
          end
        end
      end

      it "releases the fibers with the value" do
        invoke
        (0...fiber_count).each do |i|
          expect(out[i]).to eq(value)
        end
      end

      it "releases all waiters on the target" do
        expect(subject.loom.waiter_count(target)).to eq(fiber_count)
        invoke
      end

      it "emits 'fiber_release' with the target and waiter count" do
        expect(tracer).to receive(:fiber_release).with(target, fiber_count)
        invoke
      end
    end

  end

  describe '#resolve' do

    let(:value) { 4 }

    def invoke
      subject.resolve(target, value)
    end

    context "when there are no proxies for the target" do
      it "is a no-op" do
        invoke
      end
    end

    context "when there is a proxy for the target" do
      before do
        @proxy = subject.proxy(target) do
          # This should never happen.
          raise Xe::Test::Error
        end
      end

      it "resolves the proxy" do
        invoke
        expect(@proxy.__resolved?).to be_true
      end

      it "resolves the proxy with a value" do
        invoke
        expect(@proxy.__value?).to be_true
      end

      it "invalidates the proxy" do
        invoke
        expect(@proxy.__valid?).to be_false
      end

      it "sets the correct value as the proxy's subject" do
        invoke
        expect(@proxy.__subject).to eq(value)
      end

      it "emits 'proxy_resolve' with a target and count" do
        expect(tracer).to receive(:proxy_resolve) do |_target, _count|
          expect(_target).to eq(target)
          expect(_count).to eq(1)
        end
        invoke
      end

      context "when the value is itself a proxy" do
        let(:target2) { Xe::Target.new(realizers[2], 0, 'b') }
        let(:value2) { 4 }

        let(:value) { @proxy2 }

        before do
          @proxy2 = subject.proxy(target2) { value2 }
        end

        it "resolves the proxy" do
          invoke
          expect(@proxy.__resolved?).to be_true
        end

        it "resolves the proxy with a proxy" do
          invoke
          expect(@proxy.__value?).to be_false
        end

        it "invalidates the proxy" do
          invoke
          expect(@proxy.__valid?).to be_false
        end

        it "sets the correct value as the proxy's subject" do
          invoke
          # Compare the proxies by their lazy-assigned id.
          expect(@proxy.__subject.__proxy_id).to eql(@proxy2.__proxy_id)
        end

        context "after resolving the subjects" do
          before do
            invoke
            @proxy.to_i
            @proxy2.to_i
          end

          it "has the value of the second" do
            expect(@proxy.to_i).to eq(@proxy2.to_i)
          end

          it "has memoized the value of the second in the first" do
            expect(@proxy.__value?).to be_true
          end
        end
      end
    end

  end

  describe '#release_all_fibers!' do

    context "when no fibers are waiting" do
      it "is a no-op" do
        subject.release_all_fibers!
      end
    end

    context "when there are waiting fibers" do
      let(:fiber_count) { 2 }

      before do
        @fibers = (0...fiber_count).map do |i|
          subject.begin_fiber do
            subject.wait(target) do
              # This should never happen.
              raise Xe::Test::Error
            end
          end
        end
      end

      it "releases all fibers" do
        subject.release_all_fibers!
        @fibers.each { |f| expect(f).to_not be_alive }
      end
    end

  end

  describe '#invalidate_proxies!' do

    context "when the context has no proxies" do
      it "is a no-op" do
        subject.invalidate_proxies!
      end
    end

    context "when the context has proxies" do
      before do
        @proxies = realizers.map do |realizer|
          target = Xe::Target.new(realizer, 0, 'a')
          subject.proxy(target) do
            # This should never happen.
            raise Xe::Test::Error
          end
        end
      end

      it "invalidates the proxies" do
        subject.invalidate_proxies!
        @proxies.each do |proxy|
          expect(proxy.__valid?).to be_false
        end
      end
    end

  end

  describe '#trace' do

    context "when the context has no tracer" do
      before do
        options.merge!(:tracer => nil)
      end

      it "is a no-op" do
        subject.trace(:finalize_start)
      end
    end

    context "When the context has a tracer" do
      before do
        options.merge!(:tracer => tracer)
      end

      it "calls the tracer" do
        tracer.should_receive(:call).with(:finalize_start)
        subject.trace(:finalize_start)
      end
    end

  end

  describe '#inspect' do

    context "when the context is valid" do
      it "is a string" do
        expect(subject.inspect).to be_an_instance_of(String)
      end
    end

    context "when the context is invalid" do
      it "is a string" do
        expect(subject.inspect).to be_an_instance_of(String)
      end
    end

  end

  describe '#to_s' do

    it "is a string" do
      expect(subject.to_s).to be_an_instance_of(String)
    end

  end

end
