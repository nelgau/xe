require 'spec_helper'

describe Xe::Enumerator do

  subject do
    Xe::Enumerator.new(context, enumerable, options)
  end

  let(:context) do
    double(Xe::Context).tap do |context|
      context.stub(:enabled?) { enabled }
    end
  end

  let(:mapper) do
    double(mapper_class).tap do |mapper|
      mapper.stub(:call)
    end
  end

  let(:enumerable) { [1, 2, 3] }
  let(:options)    { {} }

  describe '#initialize' do

    context "when no context is given" do
      let(:context) { nil }

      it "raises Xe::NoContextError" do
        expect { subject }.to raise_error(Xe::NoContextError)
      end
    end

    it "sets the context attribute" do
      expect(subject.context).to eq(context)
    end

    it "sets the enum attribute" do
      expect(subject.enum).to eq(enumerable)
    end

    it "sets the options attribute" do
      expect(subject.options).to eq(options)
    end

    context "when the tag options is given" do
      let(:tag) { 'foo' }

      before do
        options.merge!(:tag => tag)
      end

      it "sets the tag attribute to the given" do
        expect(subject.tag).to eq(tag)
      end
    end

  end

  describe '#inspect' do

    context "when the enumerable is a collection" do
      let(:enumerable) { [1, 2, 3] }

      it "is a string" do
        expect(subject.inspect).to be_an_instance_of(String)
      end
    end

    context "when the enumerable is another instance of Xe::Enumerator" do
      let(:enumerable)  { enumerator2 }
      let(:enumerator2) { Xe::Enumerator.new(context, enumerable2) }
      let(:enumerable2) { [4, 5, 6] }

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
