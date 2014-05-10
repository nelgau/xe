require 'spec_helper'

describe "Xe::Context - Garbage Collection" do
  include Xe::Test::GC

  let(:realizer) do
    Xe.realizer do |xs|
      xs.each_with_object({}) do |x, rs|
        rs[x] = x + 1
      end
    end
  end

  def run_fiber
    Fiber.new(&method(:fiber_payload)).resume
  end

  def fiber_payload
    realizer[1].to_i
  end

  context "when waiting and dispatching (unwrapped)" do

    context "when nominal" do
      define_test! has_output: false

      def invoke
        Xe::Context.current = Xe::Context.new({})
        run_fiber
        Xe::Context.current.finalize!
      ensure
        Xe::Context.current.invalidate!
        Xe::Context.clear_current
      end
    end

    context "when #finalize! is not invoked" do
      define_test! has_output: false

      def invoke
        Xe::Context.current = Xe::Context.new({})
        run_fiber
      ensure
        Xe::Context.current.invalidate!
        Xe::Context.clear_current
      end
    end

    context "when #invalidate is not invoked" do
      define_test! has_output: false

      def invoke
        Xe::Context.current = Xe::Context.new({})
        run_fiber
        Xe::Context.current.finalize!
      ensure
        Xe::Context.clear_current
      end
    end

    context "when an exception is raised after starting the fiber" do
      define_test_with_exception!

      def invoke
        Xe::Context.current = Xe::Context.new({})
        run_fiber
        raise_exception
      ensure
        Xe::Context.clear_current
      end
    end

  end

  context "when waiting and dispatching (wrapped)" do
    define_test! has_output: false

    def invoke
      Xe.context do
        run_fiber
      end
    end
  end

  context "with an enumerator" do
    define_test! has_output: false

    def invoke
      Xe.context do
        Xe.enum([1, 2, 3]).inject(0) do |sum, x|
          sum + realizer[x].to_i
        end
      end
    end
  end

  context "when an exception is raised within the context" do
    define_test_with_exception!

    def invoke
      Xe.context { raise_exception }
    end
  end
end
