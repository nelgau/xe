require 'spec_helper'

describe "Xe::Loom::Yield - Garbage Collection" do
  include Xe::Test::GC

  context "when waiting and releasing a fiber" do
    define_test! has_output: false

    def invoke
      loom = Xe::Loom::Yield.new
      fiber = Fiber.new { loom.wait(1, Proc.new {}) }
      fiber.resume
      loom.release(1, 2)
    end
  end
end
