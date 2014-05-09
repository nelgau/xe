require 'spec_helper'

# Xe.configure do |c|
#   c.logger = :stdout
# end

# Xe::Proxy.debug!

describe "Xe - Garbage Collection" do
  include Xe::Test::GC

  let(:realizer_value) do
    Xe.realizer do |xs|
      xs.each_with_object({}) { |x, rs| rs[x] = x + 1 }
    end
  end

  let(:realizer_defer) do
    Xe.realizer do |xs|
      xs.each_with_object({}) { |x, rs| rs[x] = realizer_value[x] }
    end
  end

  context "when creating a context using 'Xe.context'" do
    define_test :has_output => false

    def invoke
      Xe.context {}
    end
  end

  context "with a single-valued enumerator (first)" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { 1 }

    def invoke
      Xe.context do
        Xe.enum(input).first
      end
    end
  end

  context "with a single-valued enumerator (inject)" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { 6 }

    def invoke
      Xe.context do
        Xe.enum(input).inject(0) { |sum, x| sum + x }
      end
    end
  end

  context "with a single-valued enumerator with realized values (inject)" do
    define_test :has_output => false

    let(:input)  { [1] }
    let(:output) { 5 }

    def invoke
      Xe.context do
        Xe.enum(input).inject(0) do |sum, x|
          sum + realizer_value[x].to_i
        end
      end
    end
  end


  context "when mapping values to values" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { [2, 3, 4] }

    def invoke
      Xe.context do
        Xe.map(input) { |x| x + 1 }
      end
    end
  end

  context "when mapping value to value (nested)" do
    define_test

    let(:input)  { [[1, 2], [3, 4], [5, 6]] }
    let(:output) { [[2, 3], [4, 5], [6, 7]] }

    def invoke
      Xe.context do
        Xe.map(input) do |arr|
          Xe.map(arr) { |x| x + 1 }
        end
      end
    end
  end

  context "when mapping values to unrealized values" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { [2, 3, 4] }

    def invoke
      Xe.context do
        Xe.map(input) { |x| realizer_value[x] }
      end
    end
  end

  context "when mapping values to unrealized values (nested)" do
    define_test

    let(:input)  { [[1, 2], [3, 4], [5, 6]] }
    let(:output) { [[2, 3], [4, 5], [6, 7]] }

    def invoke
      Xe.context do
        Xe.map(input) do |arr|
          Xe.map(arr) { |x| realizer_value[x] }
        end
      end
    end
  end

  context "when mapping values to realized values" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { [2, 3, 4] }

    def invoke
      Xe.context do
        Xe.map(input) { |x| realizer_value[x].to_i }
      end
    end
  end

  context "when mapping values to realized values (nested)" do
    define_test

    let(:input)  { [[1, 2], [3, 4], [5, 6]] }
    let(:output) { [[2, 3], [4, 5], [6, 7]] }

    def invoke
      Xe.context do
        Xe.map(input) do |arr|
          Xe.map(arr) { |x| realizer_value[x].to_i }
        end
      end
    end
  end

  context "when mapping values to deferred unrealized values" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { [2, 3, 4] }

    def invoke
      Xe.context do
        Xe.map(input) { |x| realizer_defer[x] }
      end
    end
  end

  context "when mapping values to deferred unrealized values (nested)" do
    define_test

    let(:input)  { [[1, 2], [3, 4], [5, 6]] }
    let(:output) { [[2, 3], [4, 5], [6, 7]] }

    def invoke
      Xe.context do
        Xe.map(input) do |arr|
          Xe.map(arr) { |x| realizer_defer[x] }
        end
      end
    end
  end

  context "when mapping values to deferred unrealized values" do
    define_test

    let(:input)  { [1, 2, 3] }
    let(:output) { [2, 3, 4] }

    def invoke
      Xe.context do
        Xe.map(input) { |x| realizer_defer[x].to_i }
      end
    end
  end

  context "when mapping values to deferred unrealized values (nested)" do
    define_test

    let(:input)  { [[1, 2], [3, 4], [5, 6]] }
    let(:output) { [[2, 3], [4, 5], [6, 7]] }

    def invoke
      Xe.context do
        Xe.map(input) do |arr|
          Xe.map(arr) { |x| realizer_defer[x].to_i }
        end
      end
    end
  end

end
