require 'spec_helper'

describe "Xe - Garbage Collection (Deadlock)" do
  include Xe::Test::GC

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

  context "when a fiber is waiting and never released" do
    define_test_with_exception!

    def invoke
      Xe.context do |c|
        new_waiting_fiber(c)
        Xe.map([1, 2, 3]) { |i| i }
      end
    rescue Xe::DeadlockError
      raise_exception
    end
  end

  context "when we run out of fibers and of events to realize" do
    define_test_with_exception!

    let(:max_fibers)  { 10 }
    let(:fiber_count) { max_fibers + 1 }

    def invoke
      Xe.context(max_fibers: max_fibers) do |c|
        fiber_count.times { new_waiting_fiber(c) }
      end
    rescue Xe::DeadlockError
      raise_exception
    end
  end

end
