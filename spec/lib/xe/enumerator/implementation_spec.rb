require 'spec_helper'

describe Xe::Enumerator::Implementation do

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

  let(:enabled)    { true }
  let(:enumerable) { [1, 2, 3] }
  let(:options)    { {} }

  let(:mapper_class) { Xe::Enumerator::Strategy::Mapper }
  let(:map_proc)     { Proc.new { |x| x + 1 } }
  let(:each_proc)    { Proc.new { |x| x } }

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

    it "sets the enumerable attribute" do
      expect(subject.enumerable).to eq(enumerable)
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

  describe '#map' do

    let(:expected_result) { enumerable.map(&map_proc) }

    def invoke
      subject.map(&map_proc)
    end

    context "with a mock context and mapper" do
      before do
        mapper_class.stub(:new) { mapper }
      end

      context "when the context is enabled" do
        let(:enabled) { true }

        it "constructs a new Xe::Enumerator::Strategy::Mapper" do
          expect(mapper_class).to receive(:new) do |_context, &_map_proc|
            expect(_context).to eq(context)
            expect(_map_proc).to eq(_map_proc)
            mapper
          end
          invoke
        end

        it "invokes the strategy instance" do
          expect(mapper).to receive(:call)
          invoke
        end

        it "returns the result values of the strategy" do
          mapper.stub(:call).and_return([5, 6, 7])
          expect(invoke).to eq([5, 6, 7])
        end

      end

      context "when the context is disabled" do
        let(:enabled) { false }

        it "maps using the standard enumerable method" do
          expect(invoke).to eq(expected_result)
        end
      end
    end

    context "with an actual context" do
      let(:context) { Xe::Context.new(:enabled => true) }

      it "maps values to values" do
        expect(invoke).to eq(expected_result)
      end
    end

  end

  describe '#each' do

    def invoke
      subject.each(&each_proc)
    end

    context "with a mock context and mapper" do
      before do
        mapper_class.stub(:new) { mapper }
      end

      context "when the context is enabled" do
        let(:enabled) { true }

        it "constructs a new Xe::Enumerator::Strategy::Mapper" do
          expect(mapper_class).to receive(:new) do |_context, &_map_proc|
            expect(_context).to eq(context)
            expect(_map_proc).to be_an_instance_of(::Proc)
            mapper
          end
          invoke
        end

        it "passes a map_proc that calls each_proc with the given object" do
          captured_map_proc = nil
          expect(mapper_class).to receive(:new) do |_context, &_map_proc|
            captured_map_proc = _map_proc
            mapper
          end
          invoke

          expect(each_proc).to receive(:call).with(10)
          captured_map_proc.call(10)
        end

        it "passes a map_proc that returns the given object" do
          captured_map_proc = nil
          expect(mapper_class).to receive(:new) do |_context, &_map_proc|
            captured_map_proc = _map_proc
            mapper
          end
          invoke

          result = captured_map_proc.call(11)
          expect(result).to eq(11)
        end
      end

      context "when the context is disabled" do
        let(:enabled) { false }

        it "returns an equal collection" do
          expect(invoke).to eq(enumerable)
        end

        it "invokes the block once for each element" do
          captured_objects = []
          each_proc.stub(:call) { |o| captured_objects << o }
          invoke
          expect(captured_objects).to eq(enumerable)
        end
      end
    end

    context "with an actual context" do
      let(:context) { Xe::Context.new(:enabled => true) }

      it "returns an equal collection" do
        expect(invoke).to eq(enumerable)
      end

      it "invokes the block once for each element" do
        captured_objects = []
        each_proc.stub(:call) { |o| captured_objects << o }
        invoke
        expect(captured_objects).to eq(enumerable)
      end
    end

  end

end
