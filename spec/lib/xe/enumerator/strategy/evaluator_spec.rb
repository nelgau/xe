require 'spec_helper'

describe Xe::Enumerator::Strategy::Evaluator do
  include Xe::Test::Mock::Enumerator::Strategy

  subject { Xe::Enumerator::Strategy::Evaluator.new(context, &value_proc) }

  let(:context)    { new_context_mock(&finalize_proc) }
  let(:deferrable) { Xe::Deferrable.new }

  let(:finalize_proc) { Proc.new {} }
  let(:value_proc)    { Proc.new { value } }
  let(:value)         { 4 }

  describe '#initialize' do

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
      expect(context).to receive(:begin_fiber).and_call_original
      subject.call
    end

    context "within a new fiber" do
      let(:value_proc) { Proc.new { @eval_fiber = ::Fiber.current; value } }

      it "executes value_proc" do
        subject.call
        expect(@eval_fiber).to eq(context.last_fiber)
      end
    end

    context "when eval_proc doesn't block" do
      let(:value_proc) { Proc.new { value } }
      let(:value)      { 4 }

      before do
        @result = subject.call
      end

      it "returns the result value" do
        expect(@result).to eq(4)
      end

      it "terminates the fiber" do
        expect(context.last_fiber).to_not be_alive
      end
    end

    context "when eval_proc blocks" do
      let(:wait_target)   { Xe::Target.new(deferrable, 0, 0) }
      let(:value_proc)    { Proc.new { context.wait(wait_target) } }
      let(:target_value)  { 5 }

      let(:finalize_proc) do
        Proc.new { context.dispatch(wait_target, target_value) }
      end

      before do
        @result = subject.call
      end

      it "returns a proxy instance" do
        expect(is_proxy?(@result)).to be_true
      end

      context "when wait_target's value becomes available" do
        it "calls dispatch on the context" do
          expect(context).to receive(:dispatch)
          context.dispatch(wait_target, target_value)
        end

        it "sets the value of the proxy" do
          context.dispatch(wait_target, target_value)
          expect(@result.subject).to eq(target_value)
        end
      end

      context "when there are fibers waiting on the result" do
        before do
          @resolve_value = nil
          @resolve_fiber = context.begin_fiber do
            @resolve_value = @result.resolve
          end
        end

        it "releases the fiber" do
          context.dispatch(wait_target, target_value)
          expect(@resolve_fiber).to_not be_alive
        end

        it "releases the fiber with the correct value" do
          context.dispatch(wait_target, target_value)
          expect(@resolve_value).to eq(5)
        end
      end

      context "when the proxy is resolved outside of a managed fiber" do
        it "calls finalize! on the context" do
          expect(context).to receive(:finalize!)
          @result.resolve
        end

        it "sets the value of the proxy" do
          context.dispatch(wait_target, target_value)
          expect(@result.subject).to eq(target_value)
        end
      end
    end

  end

end
