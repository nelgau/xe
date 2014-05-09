require 'spec_helper'

describe Xe::Context do
  include Xe::Test::GC

  let(:realizer) do
    Xe.realizer do |xs|
      xs.each_with_object({}) { |x, rs| rs[x] = x + 1 }
    end
  end

  context "when waiting and dispatching (unwrapped)" do
    define_test! :has_output => false

    def invoke
      Xe::Context.current = Xe::Context.new({})
      Fiber.new(&method(:fiber)).resume
      Xe::Context.current.finalize
      Xe::Context.clear_current
    end

    def fiber
      realizer[1].to_i
    end
  end

  context "when waiting and dispatching (wrapped)" do
    define_test! :has_output => false

    def invoke
      Xe.context do
        Fiber.new(&method(:fiber)).resume
      end
    end

    def fiber
      realizer[1].to_i
    end
  end

  context "with an enumerator" do
    define_test! :has_output => false

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
