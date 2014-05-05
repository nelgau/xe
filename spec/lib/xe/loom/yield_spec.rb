require 'spec_helper'

describe Xe::Loom::Yield do

  let(:wait_fiber) do
    subject.new_fiber do |out|
      out[:value] = subject.wait('a')
    end
  end

  describe '#wait' do

    context "when the current fiber is unmanaged" do
      it "invokes the block" do
        captured_key = nil
        subject.wait('a') { |key| captured_key = key }
        expect(captured_key).to eq('a')
      end
    end

    context "when the current fiber is managed" do
      it "pushes the fiber onto the queue of waiters for that key" do
        subject.run_fiber(wait_fiber)
        expect(subject.waiters['a']).to eq([wait_fiber])
      end
    end

  end

  describe '#release' do

    context "when there are no waiters on the given key" do
      it "is a no-op" do
        subject.release('a', 'b')
      end
    end

    context "when there is a fiber waiting on the given key" do
      let(:out) { {} }

      before do
        subject.run_fiber(wait_fiber, out)
      end

      it "returns control to the fiber with the given value" do
        subject.release('a', 'b')
        expect(out[:value]).to eq('b')
      end
    end

  end

  describe '#current_depth' do

    context "when the current fiber is unmanaged" do
      it "is zero" do
        expect(subject.current_depth).to eq(0)
      end
    end

    context "when the current fiber is managed" do
      it "is the depth of the current fiber" do
        captured_depth = nil
        fiber = subject.new_fiber { captured_depth = subject.current_depth }
        subject.run_fiber(fiber)
        expect(captured_depth).to eq(fiber.depth)
      end

    end

  end

end
