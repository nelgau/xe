require 'spec_helper'

describe Xe::Loom::Fiber do

  subject { Xe::Loom::Fiber.new(loom, depth, &proc) }

  let(:loom)  { Xe::Loom::Default.new }
  let(:depth) { 0 }
  let(:args)  { [1, 2, 3] }
  let(:out)   { {} }

  let(:proc) do
    Proc.new do |out, *args|
      out[:ran] = true
      out[:args] = args
    end
  end

  describe '#initialize' do

    it "sets the loom attribute" do
      expect(subject.loom).to eq(loom)
    end

    it "sets the depth attribute" do
      expect(subject.depth).to eq(depth)
    end

  end

  describe '#run' do

    it "invokes #run_fiber on the loom" do
      expect(loom).to receive(:run_fiber).with(subject, *args)
      subject.run(*args)
    end

    it "runs the fiber with the given arguments" do
      subject.run(out, *args)
      expect(out[:ran]).to be_true
      expect(out[:args]).to eq(args)
    end

  end

end
