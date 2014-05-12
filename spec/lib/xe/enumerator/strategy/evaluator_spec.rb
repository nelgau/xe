require 'spec_helper'

describe Xe::Enumerator::Strategy::Evaluator do
  include Xe::Test::Mock::Enumerator::Strategy

  subject { Xe::Enumerator::Strategy::Evaluator.new(context, &value_proc) }

  let(:context)       { new_context_mock(&finalize_proc) }
  let(:value_proc)    { Proc.new { value } }
  let(:finalize_proc) { Proc.new {} }
  let(:value)         { 4 }

  let(:deferrable)    { Xe::Deferrable.new }

  let(:wait_target)   { Xe::Target.new(deferrable, 0, 0) }
  let(:wait_value)    { 5 }

  let(:blocking_proc) { Proc.new { context.wait(wait_target) } }

  def dispatch_blocking_result
    context.dispatch(wait_target, wait_value)
  end

  describe '#initialize' do

    it "delegates to super to set the context" do
      expect(subject.context).to eq(context)
    end

    it "sets the value_proc attribute" do
      expect(subject.value_proc).to eq(value_proc)
    end

    context "when value_proc is not given" do
      let(:value_proc) { nil }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

  end

  describe '#call' do

    it "begins a fiber" do
      expect(context).to receive(:begin_fiber).once.and_call_original
      subject.call
    end

    context "within a new fiber" do
      let(:value_proc) { Proc.new { @eval_fiber = ::Fiber.current; value } }

      it "calls value_proc" do
        subject.call
        expect(@eval_fiber).to eq(context.last_fiber)
      end
    end

    context "when eval_proc doesn't wait" do
      let(:value_proc) { Proc.new { value } }
      let(:value)      { 4 }

      it "returns the expected result" do
        result = subject.call
        expect(result).to eq(value)
      end

      it "allows the fiber to terminate" do
        subject.call
        expect(context.last_fiber).to_not be_alive
      end
    end

    context "when eval_proc waits once" do
      let(:value_proc)    { blocking_proc }
      let(:finalize_proc) { Proc.new { dispatch_blocking_result } }

      before do
        @result = subject.call
      end

      it "substitutes a proxy for the result" do
        expect(is_proxy?(@result)).to be_true
      end

      context "when the attended (waited) value becomes available" do
        it "calls dispatch on the context" do
          expect(context).to receive(:dispatch)
          context.dispatch(wait_target, wait_value)
        end

        it "resolves the subject of the proxy" do
          context.dispatch(wait_target, wait_value)
          expect(@result.subject).to eq(wait_value)
        end
      end

      context "when there is a fiber waiting on the result" do
        before do
          @resolve_value = nil
          @resolve_fiber = context.begin_fiber do
            @resolve_value = @result.resolve
          end
        end

        it "releases the fiber" do
          context.dispatch(wait_target, wait_value)
          expect(@resolve_fiber).to_not be_alive
        end

        it "releases the fiber with the correct value" do
          context.dispatch(wait_target, wait_value)
          expect(@resolve_value).to eq(wait_value)
        end
      end

      context "when outside of a managed fiber" do
        it "calls finalize! on the context when the proxy is resolved" do
          expect(context).to receive(:finalize!)
          @result.resolve
        end

        it "sets the subject of the proxy when the proxy is resolved" do
          @result.resolve
          expect(@result.subject).to eq(wait_value)
        end
      end
    end

  end

end
