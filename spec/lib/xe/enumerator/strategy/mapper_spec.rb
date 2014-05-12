require 'spec_helper'

describe Xe::Enumerator::Strategy::Mapper do
  include Xe::Test::Mock::Enumerator::Strategy

  subject do
    Xe::Enumerator::Strategy::Mapper.new(context, enumerable, &map_proc)
  end

  # Don't use a real context here so we can test these strategy is isolation,
  # without invoking the full complexity of the gem (like scheduling, policies
  # and the loom).

  let(:context)       { new_context_mock(&finalize_proc) }
  let(:map_proc)      { double_proc }
  let(:finalize_proc) { Proc.new {} }

  let(:enumerable)    { [0, 1, 2, 3, 4, 5] }
  let(:double_proc)   { Proc.new { |i| i * 2 } }
  let(:expected)      { enumerable.map(&double_proc) }

  let(:deferrable)    { Xe::Deferrable.new }
  let(:wait_index)    { 2 }

  let(:one_wait_proc) do
    Proc.new do |index|
      value = (index == wait_index) ? wait_for_index(index) : index
      double_proc.call(value)
    end
  end

  let(:all_wait_proc) do
    Proc.new do |index|
      value = wait_for_index(index)
      double_proc.call(value)
    end
  end

  def target_for_index(index)
    Xe::Target.new(deferrable, index, 0)
  end

  def wait_for_index(index)
    context.wait(target_for_index(index))
  end

  def dispatch_for_index(index)
    target = target_for_index(index)
    context.dispatch(target, index)
  end

  def dispatch_one_wait_result
    dispatch_for_index(wait_index)
  end

  def dispatch_all_wait_results
    enumerable.each { |index| dispatch_for_index(index) }
  end

  describe '#initialize' do

    it "delegates to super to set the context" do
      expect(subject.context).to eq(context)
    end

    it "sets the enumerable attribute" do
      expect(subject.enumerable).to eq(enumerable)
    end

    it "sets the map_proc attribute" do
      expect(subject.map_proc).to eq(map_proc)
    end

    context "when map_proc is not given" do
      let(:map_proc) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#call' do

    context "when map_proc doesn't wait" do
      it "returns the mapping of map_proc over the enumerable" do
        expect(subject.call).to eq (expected)
      end

      it "invokes #advance once" do
        expect(subject).to receive(:advance).once.and_call_original
        subject.call
      end
    end

    context "when map_proc waits once" do
      let(:map_proc)      { one_wait_proc }
      let(:finalize_proc) { Proc.new { dispatch_one_wait_result } }

      it "returns a proxy in place of the deferred value" do
        results = subject.call
        expect(is_proxy?(results[wait_index])).to be_true
      end

      it "invokes #advance twice" do
        expect(subject).to receive(:advance).twice.and_call_original
        subject.call
      end

      context "when the enumeration is complete" do
        before do
          @results = subject.call
          @proxy = @results[wait_index]
        end

        context "when the attended (waited) value is resolved" do
          it "calls dispatch on the context" do
            expect(context).to receive(:dispatch)
            dispatch_one_wait_result
          end

          it "sets the value of the proxy after waiting" do
            dispatch_one_wait_result
            expect(@proxy.subject).to eq(expected[wait_index])
          end
        end

        context "when there is a fiber waiting on the result" do
          before do
            @resolve_value = nil
            @resolve_fiber = context.begin_fiber do
              @resolve_value = @proxy.resolve
            end
          end

          it "releases the fiber" do
            dispatch_one_wait_result
            expect(@resolve_fiber).to_not be_alive
          end

          it "releases the fiber with the correct value" do
            dispatch_one_wait_result
            expect(@resolve_value).to eq(expected[wait_index])
          end
        end

        context "when outside of a managed fiber" do
          it "calls finalize! on the context when the proxy is resolved" do
            expect(context).to receive(:finalize!)
            @proxy.resolve
          end

          it "sets the subject of the proxy when the proxy is resolved" do
            @proxy.resolve
            expect(@proxy.subject).to eq(expected[wait_index])
          end
        end
      end
    end

  end

  describe '#done?' do

    context "when enumeration is not complete" do
      it "is false" do
        expect(subject).to_not be_done
      end
    end

    context "when enumeration begins but is incomplete" do
      let(:map_proc) { one_wait_proc }

      it "is false" do
        expect(subject).to_not be_done
      end
    end

    context "when enumeration is complete" do
      before do
        subject.call
      end

      it "is true" do
        expect(subject).to be_done
      end
    end

  end

  describe '#advance' do

    it "begins a fiber" do
      expect(context).to receive(:begin_fiber).once.and_call_original
      subject.advance
    end

    context "within a new fiber" do
      let(:map_proc) do
        Proc.new do |x|
          @map_fiber = ::Fiber.current
          x + 1
        end
      end

      it "calls map_proc" do
        subject.advance
        expect(@map_fiber).to eq(context.last_fiber)
      end
    end

    context "when map_proc doesn't wait" do
      it "emits the expected results" do
        subject.advance
        expect(subject.results).to eq(expected)
      end

      it "allows the fiber to terminate" do
        subject.advance
        expect(context.last_fiber).to_not be_alive
      end
    end

    context "when map_proc waits once" do
      let(:map_proc) { one_wait_proc }

      it "doesn't mark the enumeration as complete" do
        expect(subject).to_not be_done
      end

      it "returns after completing the expected count of results" do
        subject.advance
        expect(subject.results.length).to eq(wait_index + 1)
      end

      it "emits values for all but the last result" do
        subject.advance
        subject.results[0...wait_index].each do |result|
          expect(is_proxy?(result)).to be_false
        end
      end

      it "emits the expected value for all but the last result" do
        subject.advance
        subject.results[0...wait_index].each_with_index do |result, index|
          expect(result).to eq(expected[index])
        end
      end

      it "substitutes a proxy for the last emitted result" do
        subject.advance
        expect(is_proxy?(subject.results.last)).to be_true
      end

      shared_examples_for "a suspended, completed enumeration" do
        it "completes the enumeration" do
          subject.advance
          expect(subject).to be_done
        end

        it "returns after completing the expected count of results" do
          subject.advance
          expect(subject.results.length).to eq(expected.length)
        end

        it "emits values for all but the proxied result" do
          subject.advance
          subject.results.each_with_index do |result, index|
            next if index == wait_index
            expect(is_proxy?(result)).to be_false
          end
        end

        it "emits the expected value for all but the last results" do
          subject.advance
          subject.results.each_with_index do |result, index|
            next if index == wait_index
            expect(result).to eq(expected[index])
          end
        end

        it "substitutes a proxy for the result that suspended" do
          subject.advance
          expect(is_proxy?(subject.results[wait_index])).to be_true
        end
      end

      shared_examples_for "a proxy resolver" do
        it "resolves the subject of the proxy" do
          dispatch_one_wait_result
          proxied_value = subject.results[wait_index].subject
          expect(proxied_value).to eq(expected[wait_index])
        end
      end

      context "when returned after waiting/proxying" do
        before do
          subject.advance
        end

        it_behaves_like "a suspended, completed enumeration"

        it "calls dispatch on the context after waiting" do
          expect(context).to receive(:dispatch)
          dispatch_one_wait_result
        end

        context "when the attended (waited) value is resolved" do
          context "before completing the enumeration" do
            before do
              dispatch_one_wait_result
            end

            it_behaves_like "a suspended, completed enumeration"
            it_behaves_like "a proxy resolver"
          end

          context "after completing the enumeration" do
            before do
              subject.advance
              dispatch_one_wait_result
            end

            it_behaves_like "a suspended, completed enumeration"
            it_behaves_like "a proxy resolver"
          end
        end
      end
    end

    context "when every invocation of map_proc waits" do
      let(:map_proc) { all_wait_proc }

      it "emits one result per invocation" do
        enumerable.each_with_index do |_, index|
          subject.advance
          expect(subject.results.length).to eq(index + 1)
        end
      end

      it "creates one fiber per invocation" do
        enumerable.each do
          expect(context).to receive(:begin_fiber).and_call_original
          subject.advance
        end
      end

      context "after emitting all results" do
        before do
          enumerable.each do
            subject.advance
          end
        end

        it "doesn't mark the enumeration as done" do
          expect(subject).to_not be_done
        end

        it "marks the enumeration done as a supplementary invocation" do
          subject.advance
          expect(subject).to be_done
        end
      end

      context "after completing the enumeration" do
        before do
          subject.advance until subject.done?
        end

        it "substitutes proxies for all the results" do
          subject.results.each do |result|
            expect(is_proxy?(result)).to be_true
          end
        end

        it "calls dispatch on the context after waiting" do
          expect(context).to receive(:dispatch).exactly(expected.length).times
          dispatch_all_wait_results
        end

        it "sets the value of the proxy after waiting" do
          dispatch_all_wait_results
          subject.results.each_with_index do |result, index|
            expect(subject.results[index].subject).to eq(expected[index])
          end
        end
      end
    end

  end

end
