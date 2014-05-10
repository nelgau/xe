require 'spec_helper'

describe "Xe::Loom::Yield - Garbage Collection" do
  include Xe::Test::GC

  context "when waiting and releasing a fiber" do
    define_test!

    let(:output) { 1 }

    def invoke
      loom = Xe::Loom::Yield.new

      result = nil
      fiber = loom.new_fiber do
        result = loom.wait('a') do
          # Should never happen.
          raise_exception
        end
      end

      loom.run_fiber(fiber)
      loom.release('a', 1)

      result
    end
  end
end
