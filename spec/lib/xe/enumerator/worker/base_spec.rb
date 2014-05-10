require 'spec_helper'

describe Xe::Enumerator::Worker::Base do

  describe '#run' do

    it "raises NotImplementedError" do
      expect { subject.run }.to raise_error(NotImplementedError)
    end

  end

  describe '#proxy!' do

    it "raises NotImplementedError" do
      expect { subject.proxy! }.to raise_error(NotImplementedError)
    end

  end

  describe '#context' do

    context "when no context exists" do
      it "returns nil" do
        expect(subject.context).to be_nil
      end
    end

    context "when a context exists" do
      let(:context_mock) { double(Xe::Context) }

      before do
        Xe::Context.stub(:current) { context_mock }
      end

      it "returns the context" do
        expect(subject.context).to eq(context_mock)
      end
    end

  end

end
