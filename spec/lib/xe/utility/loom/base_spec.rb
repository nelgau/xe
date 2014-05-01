require 'spec_helper'

describe Xe::Loom::Base do

  let(:proc) do
    Proc.new do |out, *args|
      out[:ran] = true
      out[:args] = args
    end
  end

  describe '#initialize' do

    it "sets the waiters attribute" do
      expect(subject.waiters).to_not be_nil
    end

  end

  describe '#waiters' do

    it "is a hash" do
      expect(subject.waiters).to be_an_instance_of(Hash)
    end

    it "is initially empty" do
      expect(subject.waiters).to be_empty
    end

  end

  describe '#new_fiber' do

    let(:fiber) { subject.new_fiber(&proc) }

    it "returns a new instance of Xe::Fiber" do
      expect(fiber).to be_an_instance_of(Xe::Fiber)
    end

    it "returns a fiber associated to the loom" do
      expect(fiber.loom).to eq(subject)
    end

    it "returns a fiber with a depth one greater than the current depth" do
      expect(fiber.depth).to eq(subject.current_depth + 1)
    end

    it "returns a fiber with the correct execution payload" do
      out = {}
      fiber.resume(out, 1, 2, 3)
      expect(out[:ran]).to be_true
      expect(out[:args]).to eq([1, 2, 3])
    end

  end

  describe '#run_fiber' do

    let(:fiber) { subject.new_fiber(&proc) }

    it "resumes the fiber" do
      out = {}
      subject.run_fiber(fiber, out, 1, 2, 3)
      expect(out[:ran]).to be_true
      expect(out[:args]).to eq([1, 2, 3])
    end

  end

  describe '#managed_fiber?' do

    context "when the fiber is unmanaged" do
      let(:fiber) { Fiber.new {} }

      it "is false" do
        expect(subject.managed_fiber?(fiber)).to be_false
      end
    end

    context "when the fiber is managed" do
      let(:fiber) { subject.new_fiber(&proc) }

      it "is true" do
        expect(subject.managed_fiber?(fiber)).to be_true
      end
    end

  end

  describe '#wait' do

    context "when a block is given" do
      it "invokes the block with the key" do
        captured_key = nil
        subject.wait('a') { |key| captured_key = key }
        expect(captured_key).to eq('a')
      end

      it "returns the result of invoking the block" do
        result = subject.wait('a') { |key| 'b' }
        expect(result).to eq('b')
      end
    end

    context "when a block isn't given" do
      it "returns nil" do
        expect(subject.wait('a')).to be_nil
      end
    end

  end

  describe '#release' do

    it "is a no-op" do
      subject.release('a', 'b')
    end

  end

  describe '#waiters?' do

    context "when there are no waiters" do
      it "is false" do
        expect(subject.waiters?).to be_false
      end
    end

    context "when there is at least one waiter" do
      let(:fiber) { subject.new_fiber(&proc) }

      before do
        subject.push_waiter('a', fiber)
      end

      it "is true" do
        expect(subject.waiters?).to be_true
      end
    end

  end

  describe '#waiter_count' do

    let(:fiber) { subject.new_fiber(&proc) }

    context "when there's a waiter on a key" do
      before do
        subject.push_waiter('a', fiber)
      end

      it "is the count of waiters on that key" do
        expect(subject.waiter_count('a')).to eq(1)
      end
    end

    context "when there's no waiter on a key" do
      it "is zero" do
        expect(subject.waiter_count('a')).to eq(0)
      end
    end

  end

  describe '#current_depth' do

    it "is zero" do
      expect(subject.current_depth).to eq(0)
    end

  end

  describe '#push_waiter' do

    let(:fiber1) { subject.new_fiber(&proc) }
    let(:fiber2) { subject.new_fiber(&proc) }

    it "pushes a waiters onto a given key" do
      subject.push_waiter('a', fiber1)
      subject.push_waiter('a', fiber2)
      expect(subject.waiters['a']).to eq([fiber1, fiber2])
    end

  end

  describe '#pop_waiters' do

    context "when there are no waiters on a given key" do
      it "is nil" do
        expect(subject.pop_waiters('a')).to be_nil
      end

      context "when a block is given" do
        it "doesn't invoke the block" do
          did_invoke = false
          subject.pop_waiters('a') { did_invoke = true }
          expect(did_invoke).to be_false
        end
      end
    end

    context "when there are waiters on a given key" do

      let(:fiber1) { subject.new_fiber(&proc) }
      let(:fiber2) { subject.new_fiber(&proc) }

      before do
        subject.push_waiter('a', fiber1)
        subject.push_waiter('a', fiber2)
      end

      it "is an enumeration of all waiters on the key" do
        waiters = subject.pop_waiters('a')
        expect(waiters.to_a).to eq([fiber1, fiber2])
      end

      it "removes the waiters" do
        subject.pop_waiters('a')
        expect(subject.waiters.has_key?('a')).to be_false
      end

      context "when a block is given" do
        it "invokes the block with each waiter" do
          yielded_waiters = []
          subject.pop_waiters('a') do |waiter|
            yielded_waiters << waiter
          end
          expect(yielded_waiters).to eq([fiber1, fiber2])
        end

      end

    end

  end

end
