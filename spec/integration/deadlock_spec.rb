require 'spec_helper'

describe "Xe - Deadlock" do

  let(:source) { Xe::Deferrable.new }
  let(:target) { Xe::Target.new(source) }

  def new_waiting_fiber(context)
    context.begin_fiber do
      context.wait(target) do
        # This should never happen.
        raise Xe::Text::Error
      end
    end
  end

  context "when a fiber waits and is never released" do

    def invoke
      Xe.context do |c|
        new_waiting_fiber(c)
        Xe.map([1, 2, 3]) { |i| i }
      end
    end

    it "deadlocks" do
      expect { invoke }.to raise_error(Xe::DeadlockError)
    end

  end

  context "when we run out of fibers and of events to realize" do

    let(:max_fibers)  { 10 }
    let(:fiber_count) { max_fibers + 1 }

    def invoke
      Xe.context(max_fibers: max_fibers) do |c|
        fiber_count.times { new_waiting_fiber(c) }
      end
    end

    it "deadlocks" do
      expect { invoke }.to raise_error(Xe::DeadlockError)
    end

  end

end
