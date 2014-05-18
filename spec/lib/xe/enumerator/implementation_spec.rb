require 'spec_helper'

describe Xe::Enumerator::Implementation do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator
  include Xe::Test::Scenario

  subject do
    Xe::Enumerator.new(context, enumerable, options)
  end

  let(:options)    { {} }

  let(:scenario_options) { {
    :serialized => {
      :enabled => false
    },
    # The 'nested' tests require at least two fibers to prevent deadlock.
    :one_proxy => {
      :enabled => true,
      :proxies => :one
    },
    :many_proxies => {
      :enabled => true,
      :proxies => :many
    },
    :all_proxy => {
      :enabled => true,
      :proxies => :all
    }
  } }

  # Wraps the invocation of #invoke and returns the result. The default
  # implementation createds a real context.
  def around_invoke(options={})
    proxies = options.delete(:proxies)
    with_context_mock(options) do
      enum = enumerable.dup
      with_proxies(enum, type: proxies) do
        # Create a new enumerator for the specific context and enum.
        enumerator = Xe::Enumerator.new(context, enum)
        yield(enumerator)
      end
    end
  end

  def with_proxies(enum ,options={})
    type = options[:type]
    return yield if !type || type == :none
    # Conditionally, replace certain indexes in the enumerable with deferrals.
    substitute_proxies(enum, options)
    # Actually run the test.
    result = yield
    # Resolve any outstanding proxies.
    release_enumerable_waiters
    result
  end

  def substitute_proxies(enum, options={})
    case options[:type]
    when :one
      substitute_proxy(enum, 2)
    when :many
      each_index do |index|
        substitute_proxy(enum, index) if index % 2 == 0
      end
    when :all
      each_index do |index|
        substitute_proxy(enum, index)
      end
    end
  end

  def substitute_proxy(enum, index)
    enum[index] = proxy_for_index(index) do
      # These proxies should never force resolution.
      raise Xe::Test::Error
    end
  end

  describe '#map' do

    context "when a block is given" do
      expect_output!

      let(:map_proc) { Proc.new { |x| x.to_i + 1 } }
      let(:output)   { enumerable.map(&map_proc) }

      def invoke(enumerator=subject)
        enumerator.map(&map_proc)
      end

      context "with an instrumented map_proc" do
        let(:map_proc) { Proc.new { |x| captured << x } }
        let(:captured) { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(enumerable.length)
        end

        it "invokes the block once with each element" do
          invoke
          captured.zip(enumerable).each do |obj, element|
            expect(obj).to eql(element)
          end
        end
      end
    end

    context "when no block is given" do
      let(:map_proc) { nil }

      it "returns a reference to the enumerator" do
        expect(subject.map).to eql(subject)
      end
    end

  end

  describe '#collect' do
    it "is an alias for #map" do
      expect(subject.method(:collect)).to eq(subject.method(:map))
    end
  end

  describe '#each' do

    context "when a block is given" do
      expect_output!

      let(:each_proc) { Proc.new { |x| x.to_i } }
      let(:output)    { enumerable }

      def invoke(enumerator=subject)
        enumerator.each(&each_proc)
      end

      context "with an instrumented each_proc" do
        let(:each_proc) { Proc.new { |x| captured << x } }
        let(:captured)  { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(enumerable.length)
        end

        it "invokes the block once with each element" do
          invoke
          captured.zip(enumerable).each do |obj, element|
            expect(obj).to eql(element)
          end
        end
      end
    end

    context "when a block is not given" do
      let(:each_proc) { nil }

      it "returns a reference to the enumerator" do
        expect(subject.map).to eql(subject)
      end
    end

  end

  describe '#inject' do

    let(:initial)     { 33 }
    let(:inject_proc) { Proc.new { |sum, x| sum + x.to_i } }
    let(:output)      { enumerable.inject(initial, &inject_proc) }

    context "when an initial value and a block is given" do
      expect_output!

      def invoke(enumerator=subject)
        enumerator.inject(initial, &inject_proc)
      end

      context "with an instrumented inject_proc" do
        let(:inject_proc) { Proc.new { |acc, x| captured << [acc, x]; x } }
        let(:captured)    { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(enumerable.length)
        end

        it "invokes the block once with each element" do
          invoke

          accumulators = [initial] + enumerable[0...-1]
          expected_captures = accumulators.zip(enumerable)

          expected_captures.each_with_index do |(acc, obj), index|
            expect(acc).to eq(captured[index][0])
            expect(obj).to eql(captured[index][1])
          end
        end
      end
    end

    context "for uses not covered by the implementation module" do
      context "when invoked with (initial, sym)" do
        let(:args) { [0, :foo] }

        it "delegates to the standard implementation" do
          expect(enumerable).to receive(:inject).with(args)
          subject.inject(args)
        end
      end

      context "when invoked with (sym)" do
        let(:args) { [:foo] }

        it "delegates to the standard implementation" do
          expect(enumerable).to receive(:inject).with(args)
          subject.inject(args)
        end
      end

      context "when invoke with a block but no initial value" do
        let(:inject_proc) { Proc.new {} }

        it "delegates to the standard implementation" do
          expect(enumerable).to receive(:inject)
          subject.inject(&inject_proc)
        end
      end
    end

  end

  describe '#reduce' do
    it "is an alias for #inject" do
      expect(subject.method(:reduce)).to eq(subject.method(:inject))
    end
  end

end
