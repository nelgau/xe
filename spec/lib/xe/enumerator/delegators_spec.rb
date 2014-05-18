require 'spec_helper'

describe Xe::Enumerator::Delegators do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator

  def self.delegated_methods
    Enumerable.instance_methods -
      Xe::Enumerator::Implementation.instance_methods
  end

  subject do
    Xe::Enumerator.new(context, enumerable)
  end

  let(:enum_args)  { [4, 5, 6] }
  let(:enum_proc)  { Proc.new { |x| x } }

  delegated_methods.each do |method|
    describe "##{method.to_s}" do

      let(:method) { method }

      def invoke
        subject.send(method, *enum_args, &enum_proc)
      end

      it "evalutes the invocation with an evaluator" do
        expect(subject).to receive(:run_evaluator)
        invoke
      end

      it "invokes ##{method} on the enumerable via the evaluator block" do
        expect(enumerable).to receive(method) do |*_enum_args, &_enum_proc|
          expect(_enum_args).to eq(enum_args)
          expect(_enum_proc).to eq(enum_proc)
        end
        invoke
      end

      it "returns the value of ##{method} via the evaluator block" do
        enumerable.stub(method).and_return(15)
        expect(invoke).to eq(15)
      end

    end
  end

end
