require 'spec_helper'

describe Xe::Enumerator::Strategy::Base do

  let(:subject) { Xe::Enumerator::Strategy::Base.new(context_mock) }
  let(:context_mock) { double(Xe::Context) }

  describe '.call' do

    let(:klass)    { Xe::Enumerator::Strategy::Base }
    let(:instance) { klass.new(context_mock) }

    before do
      instance.stub(:call)
    end

    it "creates an instance of the strategy" do
      expect(klass).to receive(:new).with(context_mock, 1, 2, 3) { instance }
      klass.call(context_mock, 1, 2, 3)
    end

    it "invokes call on the instance" do
      klass.stub(:new).and_return(instance)
      expect(instance).to receive(:call)
      klass.call(context_mock)
    end
  end

  describe '#initialize' do

    it "sets the context" do
      expect(subject.context).to eq(context_mock)
    end

  end

  describe '#call' do

    it "raises NotImplementedError" do
      expect { subject.call }.to raise_error(NotImplementedError)
    end

  end

end
