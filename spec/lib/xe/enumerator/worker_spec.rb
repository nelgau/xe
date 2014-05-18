require 'spec_helper'

describe Xe::Enumerator::Strategy::Mapper do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator

  subject do
    Xe::Enumerator::Worker.new(
      context,
      enumerable,
      :compute_proc => compute_proc,
      :results_proc => results_proc,
      :tag => tag
    )
  end

  let(:compute_proc)  { double_proc }
  let(:results_proc)  { Proc.new { |r| results << r } }
  let(:finalize_proc) { Proc.new {} }
  let(:tag)           { nil }

  let(:double_proc)   { Proc.new { |i| i * 2 } }
  let(:wait_index)    { 2 }

  let(:results)       { [] }
  let(:expected)      { enumerable.map(&double_proc) }

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

  describe '#initialize' do

    it "sets the context attribute" do
      expect(subject.context).to eq(context)
    end

    it "sets the enumerable attribute" do
      expect(subject.enumerable).to eq(enumerable)
    end

    it "sets the compute_proc attribute" do
      expect(subject.compute_proc).to eq(compute_proc)
    end

    context "when compute_proc is not given" do
      let(:compute_proc) { nil }

      it "sets the default proc" do
        expect(subject.compute_proc).to be_an_instance_of(::Proc)
      end

      it "sets a proc which is a pass-through" do
        result = subject.compute_proc.call(2)
        expect(result).to eq(2)
      end
    end

    it "sets the results_proc attribute" do
      expect(subject.results_proc).to eq(results_proc)
    end

    context "when results_proc is not given" do
      let(:results_proc) { nil }

      it "sets the default proc" do
        expect(subject.results_proc).to be_an_instance_of(::Proc)
      end

      it "sets a proc which is a no-op" do
        subject.results_proc.call(2)
      end
    end

  end

  describe '#call' do

    context "when compute_proc doesn't wait" do
      let(:compute_proc) { double_proc }

      it "returns the mapping of compute_proc over the enumerable" do
        subject.call
        expect(results).to eq (expected)
      end

      it "invokes #advance once" do
        expect(subject).to receive(:advance).once.and_call_original
        subject.call
      end
    end

    context "when compute_proc waits once" do
      let(:compute_proc)  { one_wait_proc }
      let(:finalize_proc) { Proc.new { release_enumerable_waiters } }

      it "emits a proxy in place of the deferred value" do
        subject.call
        expect(is_proxy?(results[wait_index])).to be_true
      end

      it "invokes #advance twice" do
        expect(subject).to receive(:advance).twice.and_call_original
        subject.call
      end

      context "when the enumeration is complete" do
        before do
          subject.call
        end

        let(:proxy) { results[wait_index] }

        context "when the attended (waited) value is resolved" do
          it "calls dispatch on the context" do
            expect(context).to receive(:dispatch).at_least(:once)
            release_enumerable_waiters
          end

          it "sets the value of the proxy after waiting" do
            release_enumerable_waiters
            expect(proxy.subject).to eq(expected[wait_index])
          end
        end

        context "when there is a fiber waiting on the result" do
          before do
            @resolve_value = nil
            @resolve_fiber = context.begin_fiber do
              @resolve_value = proxy.resolve
            end
          end

          it "releases the fiber" do
            release_enumerable_waiters
            expect(@resolve_fiber).to_not be_alive
          end

          it "releases the fiber with the correct value" do
            release_enumerable_waiters
            expect(@resolve_value).to eq(expected[wait_index])
          end
        end

        context "when outside of a managed fiber" do
          it "calls finalize! on the context when the proxy is resolved" do
            expect(context).to receive(:finalize!)
            proxy.resolve
          end

          it "sets the subject of the proxy when the proxy is resolved" do
            proxy.resolve
            expect(proxy.subject).to eq(expected[wait_index])
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
      let(:compute_proc) { one_wait_proc }

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
      let(:compute_proc) do
        Proc.new do |x|
          @map_fiber = ::Fiber.current
          x + 1
        end
      end

      it "calls compute_proc" do
        subject.advance
        expect(@map_fiber).to eq(context.last_fiber)
      end
    end

    context "when compute_proc doesn't wait" do
      let(:compute_proc) { double_proc }

      it "emits the expected results" do
        subject.advance
        expect(results).to eq(expected)
      end

      it "allows the fiber to terminate" do
        subject.advance
        expect(context.last_fiber).to_not be_alive
      end
    end

    context "when compute_proc waits once" do
      let(:compute_proc) { one_wait_proc }

      it "doesn't mark the enumeration as complete" do
        expect(subject).to_not be_done
      end

      it "returns after emitting the expected count of results" do
        subject.advance
        expect(results.length).to eq(wait_index + 1)
      end

      it "emits values for all but the last result" do
        subject.advance
        results[0...wait_index].each do |result|
          expect(is_proxy?(result)).to be_false
        end
      end

      it "emits the expected value for all but the last result" do
        subject.advance
        results[0...wait_index].each_with_index do |result, index|
          expect(result).to eq(expected[index])
        end
      end

      it "emits a proxy for the last unrealized result" do
        subject.advance
        expect(is_proxy?(results.last)).to be_true
      end

      shared_examples_for "a suspended, completed enumeration" do
        it "completes the enumeration" do
          subject.advance
          expect(subject).to be_done
        end

        it "returns after completing the expected count of results" do
          subject.advance
          expect(results.length).to eq(expected.length)
        end

        it "emits values for all but the proxied result" do
          subject.advance
          results.each_with_index do |result, index|
            next if index == wait_index
            expect(is_proxy?(result)).to be_false
          end
        end

        it "emits the expected value for all but the last results" do
          subject.advance
          results.each_with_index do |result, index|
            next if index == wait_index
            expect(result).to eq(expected[index])
          end
        end

        it "emits a proxy for the computation that suspended" do
          subject.advance
          expect(is_proxy?(results[wait_index])).to be_true
        end
      end

      shared_examples_for "a proxy resolver" do
        it "resolves the subject of the proxy" do
          release_enumerable_waiters
          proxied_value = results[wait_index].subject
          expect(proxied_value).to eq(expected[wait_index])
        end
      end

      context "when returned after waiting/proxying" do
        before do
          subject.advance
        end

        it_behaves_like "a suspended, completed enumeration"

        it "calls dispatch on the context after waiting" do
          expect(context).to receive(:dispatch).at_least(:once)
          release_enumerable_waiters
        end

        context "when the attended (waited) value is resolved" do
          context "before completing the enumeration" do
            before do
              release_enumerable_waiters
            end

            it_behaves_like "a suspended, completed enumeration"
            it_behaves_like "a proxy resolver"
          end

          context "after completing the enumeration" do
            before do
              subject.advance
              release_enumerable_waiters
            end

            it_behaves_like "a suspended, completed enumeration"
            it_behaves_like "a proxy resolver"
          end
        end
      end
    end

    context "when every invocation of map_proc waits" do
      let(:compute_proc) { all_wait_proc }

      it "emits one result per invocation" do
        enumerable.each_with_index do |_, index|
          subject.advance
          expect(results.length).to eq(index + 1)
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
          results.each do |result|
            expect(is_proxy?(result)).to be_true
          end
        end

        it "calls dispatch on the context after waiting" do
          expect(context).to receive(:dispatch).exactly(expected.length).times
          release_enumerable_waiters
        end

        it "sets the value of the proxy after waiting" do
          release_enumerable_waiters
          results.each_with_index do |result, index|
            expect(result.subject).to eq(expected[index])
          end
        end
      end
    end

  end

  describe '#inspect' do

    context "when the worker has a tag" do
      let(:tag) { 'foo' }

      it "is a string" do
        expect(subject.inspect).to be_an_instance_of(String)
      end
    end

    context "when the worker has no tag" do
      let(:tag) { nil }

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
