require 'spec_helper'

describe Xe::Enumerator::Delegators do

  subject do
    Xe::Enumerator.new(context, enumerable, options)
  end

  let(:context) do
    double(Xe::Context).tap do |context|
      context.stub(:enabled?) { enabled }
    end
  end

  let(:evaluator) do
    double(eval_class).tap do |evaluator|
      evaluator.stub(:call)
    end
  end

  let(:enabled)    { true }
  let(:enumerable) { [1, 2, 3] }
  let(:options)    { {} }

  let(:eval_class) { Xe::Enumerator::Strategy::Evaluator }

  let(:enum_args)  { [3, 4, 5] }
  let(:enum_proc)  { Proc.new { |x| x } }

  (Enumerable.instance_methods - [:map]).each do |method|
    describe "##{method.to_s}" do

      let(:method) { method }
      let(:airty)  { subject.method(method).arity }

      def invoke
        subject.send(method, *enum_args, &enum_proc)
      end

      context "with a mock context and mapper" do
        before do
          eval_class.stub(:new) { evaluator }
        end

        context "when the context is enabled" do
          let(:enabled) { true }

          it "constructs a new Xe::Enumerator::Strategy::Evaluator" do
            expect(eval_class).to receive(:new) do |_context, &_eval_proc|
              expect(_context).to eq(context)
              expect(_eval_proc).to be_an_instance_of(::Proc)
              evaluator
            end
            invoke
          end

          it "invokes the strategy instance" do
            expect(evaluator).to receive(:call)
            invoke
          end

          it "returns the result value of the strategy" do
            evaluator.stub(:call).and_return(11)
            expect(invoke).to eq(11)
          end

          it "invokes ##{method} on the enumerable via the evaluator block" do
            captured_eval_proc = nil
            expect(eval_class).to receive(:new) do |_, &_eval_proc|
              captured_eval_proc = _eval_proc
              evaluator
            end
            invoke

            # Except to invoke the proxied enumerable method...
            expect(enumerable).to receive(method) do |*_enum_args, &_enum_proc|
              expect(_enum_args).to eq(enum_args)
              expect(_enum_proc).to eq(enum_proc)
            end
            # ... via the evaluator block.
            captured_eval_proc.call
          end

          it "returns the value of ##{method} via the evaluator block" do
            captured_eval_proc = nil
            expect(eval_class).to receive(:new) do |_, &_eval_proc|
              captured_eval_proc = _eval_proc
              evaluator
            end
            invoke

            enumerable.stub(method) { 15 }
            expect(captured_eval_proc.call).to eq(15)
          end
        end

        context "when the context is disabled" do
          let(:enabled) { false }

          it "invokes ##{method} on the enumerable" do
            expect(enumerable).to receive(method) do |*_enum_args, &_enum_proc|
              expect(_enum_args).to eq(enum_args)
              expect(_enum_proc).to eq(enum_proc)
            end
            invoke
          end

          it "returns the value of ##{method} on the enumerable" do
            enumerable.stub(method) { 16 }
            expect(invoke).to eq(16)
          end
        end
      end

    end
  end

  describe '#inject' do

    let(:expected_result) { enumerable.inject(0, &:+) }

    def invoke
      subject.inject(0, &:+)
    end

    context "with an actual context" do
      let(:context) { Xe::Context.new(:enabled => true) }

      it "injects like an enumerable" do
        expect(invoke).to eq(expected_result)
      end
    end

  end

end
