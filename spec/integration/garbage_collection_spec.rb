require 'spec_helper'

Xe.configure do |c|
  c.logger = :stdout
end

Xe::Proxy.debug!

describe "Xe - Garbage Collection" do
  include Xe::Test::GC

  after do
    # After each test's block is out of scope, we should expect all instances
    # of context-related classes to be collected.
    expect_gc
  end

  def self.define_test(options={})
    has_output = options.fetch(:has_output, true)

    it "holds no references" do
      # Invoke the test procedure and immediately discard the result.
      result = invoke
      expect(result).to eq(output) if has_output
      result = nil
    end
  end

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

  context "with a single-valued enumerator with unrealized values (inject)" do
    define_test :has_output => false

    let(:input)  { [1, 2, 3, 4, 5, 6, 7, 8] }
    let(:output) { 5 }

    def invoke
      Xe.context do
        Xe.enum(input).inject(0) do |sum, x|
          sum + realizer_value[x]
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
          Xe.map(arr) { |x| realizer_defer[x].to_i }
        end
      end
    end
  end

end
