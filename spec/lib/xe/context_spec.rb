require 'spec_helper'
require 'set'

describe Xe::Context do
  include Xe::Test::Mock::Context::Realizer

  subject { Xe::Context.new(options) }

  let(:tracer)    { Xe::Tracer::Base.new }
  let(:options)   { { :tracer => tracer } }

  let(:realizers) do
    (0...5).map do |i|
      new_realizer_mock(i)
    end
  end

  describe '.wrap' do

  end

  describe '.exists?' do

  end

  describe '.active?' do

  end

  describe '#initialize' do

    let(:options) { {} }
    let(:config_context_options) { { :foo => :bar } }

    before do
      Xe.config.stub(:context_options) { config_context_options }
    end

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

    # it "sets the policy attribute to be an instance of Xe::Policy::Default" do
    #   expect(subject.policy).to be_an_instance_of(Xe::Policy::Default)
    # end

    context "when the policy option is given" do
      let(:policy) { double(Xe::Policy::Base) }

      before do
        options.merge!(:policy => policy)
      end

      it "sets the policy attribute to the given" do
        expect(subject.policy).to eq(policy)
      end
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

  end

  describe '#dispatch' do

  end

  describe '#proxy' do

  end

  describe '#begin_fiber' do

  end

  describe '#free_fibers' do

  end

  describe '#can_run_fiber?' do

  end

  describe '#realize_target' do

  end

  describe '#realize_event' do

  end

  describe '#wait' do

  end

  describe '#release' do

  end

  describe '#resolve' do

  end

  describe '#invalidate_proxies!' do

  end

  describe '#trace' do

  end

  describe '#inspect' do

    it "is a string" do
      expect(subject.inspect).to be_an_instance_of(String)
    end

  end

  describe '#to_s' do

    it "is a string" do
      expect(subject.to_s).to be_an_instance_of(String)
    end

  end

end
