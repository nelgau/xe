require 'spec_helper'

describe Xe::Loom::Fiber do

  subject { Xe::Loom::Fiber.new(loom, depth, &payload) }

  let(:loom)  { Xe::Loom::Default.new }
  let(:depth) { 0 }
  let(:args)  { [1, 2, 3] }
  let(:value) { 4 }
  let(:out)   { {} }

  let(:payload) do
    Proc.new do |out, *args|
      out[:ran] = true
      out[:args] = args
      value
    end
  end

  def resume_fiber
    subject.resume(out, *args)
  end

  describe '#initialize' do

    it "sets the depth attribute" do
      expect(subject.depth).to eq(depth)
    end

    it "sets the fiber's proc to delegate to the entry point" do
      expect(Xe::Loom::Fiber).to receive(:start) do |_loom, out, *_args, &_blk|
        expect(_loom).to eq(loom)
        expect(_args).to eq(_args)
        expect(_blk).to eq(payload)
      end
      resume_fiber
    end

  end

  describe '.resume' do

    it "runs the execution payload" do
      resume_fiber
      expect(out[:ran]).to be_true
      expect(out[:args]).to eq(args)
    end

    it "returns the value of the execution payload" do
      expect(resume_fiber).to eq(value)
    end

  end

  describe '.start' do

    it "calls #fiber_started! on the loom" do
      expect(loom).to receive(:fiber_started!)
      resume_fiber
    end

    it "invokes the execution payload" do
      expect(payload).to receive(:call).with(out, *args)
      resume_fiber
    end

    context "when the execution payload returns a value" do
      let(:payload) do
        Proc.new {}
      end

      it "calls #fiber_finished! on the loom" do
        expect(loom).to receive(:fiber_finished!)
        resume_fiber
      end
    end

    context "when the proc raises" do
      let(:payload) do
        Proc.new { raise Xe::Test::Error }
      end

      it "calls #fiber_finished! on the loom" do
        expect(loom).to receive(:fiber_finished!)
        expect { resume_fiber }.to raise_error(Xe::Test::Error)
      end
    end

  end

end
