require 'spec_helper'

describe Xe::Enumerator::Implementation do
  include Xe::Test::Helper::Enumerator
  include Xe::Test::Mock::Enumerator
  include Xe::Test::Scenario

  subject do
    Xe::Enumerator.new(context, enumerable, options)
  end

  let(:options) { {} }

  let(:scenario_options) { {
    :serialized => {
      :enabled => false
    },
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

  describe '#map' do

    let(:map_proc) { Proc.new { |x| x.to_i + 1 } }

    def invoke(enumerator=subject)
      enumerator.map(&map_proc)
    end

    context "when a block is given" do
      let(:output) { enumerable.map(&map_proc) }
      expect_output!

      context "with an instrumented map_proc" do
        let(:map_proc) { Proc.new { |x| captured << x } }
        let(:captured) { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
        expect(invoke).to eql(subject)
      end
    end

  end

  describe '#collect' do
    it "is an alias for #map" do
      expect(subject.method(:collect)).to eq(subject.method(:map))
    end
  end

  describe '#each' do

    let(:each_proc) { Proc.new { |x| x.to_i } }

    def invoke(enumerator=subject)
      enumerator.each(&each_proc)
    end

    context "when a block is given" do
      let(:output) { enumerable }
      expect_output!

      context "with an instrumented each_proc" do
        let(:each_proc) { Proc.new { |x| captured << x } }
        let(:captured)  { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
        expect(invoke).to eql(subject)
      end
    end

  end

  describe '#inject' do

    let(:initial)     { 33 }
    let(:inject_proc) { Proc.new { |sum, x| sum + x.to_i } }

    def invoke(enumerator=subject)
      enumerator.inject(initial, &inject_proc)
    end

    context "when an initial value and a block is given" do
      let(:output) { enumerable.inject(initial, &inject_proc) }
      expect_output!

      context "with an instrumented inject_proc" do
        let(:inject_proc) { Proc.new { |acc, x| captured << [acc, x]; x } }
        let(:captured)    { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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

  describe '#all?' do

    let(:all_proc) { Proc.new { |x| !!x && true } }

    def invoke(enumerator=subject)
      enumerator.all?(&all_proc)
    end

    context "when a block is given" do
      let(:all_proc) { Proc.new { |x| !!x && true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:all_proc) { Proc.new { |x| !!x && true } }
        let(:output)   { true }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:all_proc) { Proc.new { |x| !!x && true } }
        let(:output)   { true }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:all_proc) { Proc.new { |x| !!x && false } }
        let(:output)   { false }
        expect_output!
      end

      context "when some invocations of the block return false" do
        let(:all_proc) { Proc.new { |x| x % 3 == 0 } }
        let(:output)   { false }
        expect_output!
      end

      context "with an instrumented all_proc" do
        let(:all_proc) { Proc.new { |x| captured << x; ret_val } }
        let(:ret_val)  { true }
        let(:captured) { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
      let(:all_proc) { nil }

      context "when the enumerable is empty" do
        before { enumerable.clear }
        let(:output) { true }
        expect_output!
      end

      context "when the enumerable does not contain false or nil" do
        let(:output) { true }
        expect_output!
      end

      context "when the enumerable contains a false or nil" do
        before { enumerable[-1] = false }
        let(:output) { false }
        expect_output!
      end
    end

  end

  describe '#any?' do

    let(:any_proc) { Proc.new { |x| !!x; true } }

    def invoke(enumerator=subject)
      enumerator.any?(&any_proc)
    end

    context "when a block is given" do
      let(:any_proc) { Proc.new { |x| !!x; true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:any_proc)   { Proc.new { |x| !!x; true } }
        let(:output)     { false }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:any_proc) { Proc.new { |x| !!x; true } }
        let(:output)   { true }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:any_proc) { Proc.new { |x| !!x; false } }
        let(:output)   { false }
        expect_output!
      end

      context "when some invocations of the block return false" do
        let(:any_proc) { Proc.new { |x| x % 3 == 0 } }
        let(:output)   { true }
        expect_output!
      end

      context "with an instrumented any_proc" do
        let(:any_proc) { Proc.new { |x| captured << x; ret_val } }
        let(:ret_val)  { false }
        let(:captured) { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
      let(:any_proc) { nil }

      context "when the enumerable is empty" do
        before { enumerable.clear }
        let(:output) { false }
        expect_output!
      end

      context "when the enumerable does not contain false or nil" do
        let(:output) { true }
        expect_output!
      end

      context "when the enumerable contains only false or nil" do
        before { (0...count).each { |i| enumerable[i] = false } }
        let(:output) { false }
        expect_output!
      end
    end

  end

  describe '#none?' do

    let(:none_proc) { Proc.new { |x| !!x; true } }

    def invoke(enumerator=subject)
      enumerator.none?(&none_proc)
    end

    context "when a block is given" do
      let(:none_proc) { Proc.new { |x| !!x; true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:none_proc)  { Proc.new { |x| !!x; true } }
        let(:output)     { true }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:none_proc) { Proc.new { |x| !!x; true } }
        let(:output)    { false }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:none_proc) { Proc.new { |x| !!x; false } }
        let(:output)    { true }
        expect_output!
      end

      context "when some invocations of the block return false" do
        let(:none_proc) { Proc.new { |x| x % 3 == 0 } }
        let(:output)    { false }
        expect_output!
      end

      context "with an instrumented none_proc" do
        let(:none_proc) { Proc.new { |x| captured << x; ret_val } }
        let(:ret_val)   { false }
        let(:captured)  { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
      let(:none_proc) { nil }

      context "when the enumerable is empty" do
        before { enumerable.clear }
        let(:output) { true }
        expect_output!
      end

      context "when the enumerable does not contain false or nil" do
        let(:output) { false }
        expect_output!
      end

      context "when the enumerable contains only false or nil" do
        before { (0...count).each { |i| enumerable[i] = false } }
        let(:output) { true }
        expect_output!
      end
    end

  end

  describe '#count' do

    let(:count_proc) { Proc.new { |x| !!x; true } }

    def invoke(enumerator=subject)
      enumerator.count(&count_proc)
    end

    context "when a block is given" do
      let(:count_proc) { Proc.new { |x| !!x; true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:count_proc) { Proc.new { |x| !!x; true } }
        let(:output)     { 0 }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:count_proc) { Proc.new { |x| !!x; true } }
        let(:output)     { count }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:count_proc) { Proc.new { |x| !!x; false } }
        let(:output)     { 0 }
        expect_output!
      end

      context "when some invocations of the block return false" do
        let(:count_proc) { Proc.new { |x| x % 3 == 0 } }
        let(:output)     { enumerable.count(&count_proc) }
        expect_output!
      end

      context "with an instrumented count_proc" do
        let(:count_proc) { Proc.new { |x| captured << x; ret_val } }
        let(:ret_val)    { true }
        let(:captured)   { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
      let(:count_proc) { nil }

      context "when the enumerable is empty" do
        before { enumerable.clear }
        let(:output) { 0 }
        expect_output!
      end

      context "when the enumerable does not contain false or nil" do
        let(:output) { count }
        expect_output!
      end

      context "when the enumerable contains only false or nil" do
        before { (0...count).each { |i| enumerable[i] = false } }
        let(:output) { 0 }
        expect_output!
      end
    end

    context "when a single argument is given" do
      let(:count_arg)  { nil }
      let(:count_proc) { nil }

      def invoke(enumerator=subject)
        enumerator.count(count_arg, &count_proc)
      end

      context "when the enumerable is empty" do
        before { enumerable.clear }
        let(:count_arg) { 2 }
        let(:output) { 0 }
        expect_output!
      end

      context "when the enumerable does not contain count_arg" do
        before { (0...count).each { |i| enumerable[i] = 'a' } }
        let(:count_arg) { 'b' }
        let(:output) { 0 }
        expect_output!
      end

      context "when the enumerable contains only count_arg" do
        before { (0...count).each { |i| enumerable[i] = 'a' } }
        let(:count_arg) { 'a' }
        let(:output) { count }
        expect_output!
      end
    end

  end

  describe '#one?' do

    let(:one_proc) { Proc.new { |x| !!x; true } }

    def invoke(enumerator=subject)
      enumerator.one?(&one_proc)
    end

    context "when a block is given" do
      let(:one_proc) { Proc.new { |x| !!x; true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:one_proc)   { Proc.new { |x| !!x; true } }
        let(:output)     { false }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:one_proc) { Proc.new { |x| !!x; true } }
        let(:output)   { false }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:one_proc) { Proc.new { |x| !!x; false } }
        let(:output)   { false }
        expect_output!
      end

      context "when exactly one invocation of the block returns true" do
        let(:one_proc) { Proc.new { |x| x == (count / 2) } }
        let(:output)   { true }
        expect_output!
      end
    end

  end

  describe '#each_with_index' do

    let(:each_proc) { Proc.new { |x| } }

    # Make the enumerable distinct from the sequence of indicies.
    before { enumerable.reverse! }

    def invoke(enumerator=subject)
      enumerator.each_with_index(&each_proc)
    end

    context "when a block is given" do
      let(:each_proc) { Proc.new { |x| } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:output)     { [] }
        expect_output!
      end

      context "when the enumerable is not empty" do
        let(:output) { enumerable }
        expect_output!
      end

      context "with an instrumented each_proc" do
        let(:each_proc) { Proc.new { |x, i| captured << [x, i]; ret_val } }
        let(:ret_val)   { nil }
        let(:captured)  { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
        end

        it "invokes the block once with each element and index" do
          invoke
          captured.zip(enumerable).each_with_index do |(obj, element), index|
            expect(obj.first).to eql(element)
            expect(obj.last).to eql(index)
          end
        end
      end
    end

    context "when a block is not given" do
      let(:each_proc) { nil }

      it "returns an enumerator" do
        expect(invoke).to be_an_instance_of(Xe::Enumerator)
      end

      it "returns an enumerator of equal length" do
        expect(invoke.to_a.length).to eq(count)
      end

      it "returns an enumerator that yields a sequence of (el, idx) pairs" do
        results = invoke.to_a
        expect(results.map(&:first)).to eq(enumerable)
        expect(results.map(&:last)).to eq((0...count).to_a)
      end
    end

  end

  describe '#each_with_object' do

    let(:object)    { {} }
    let(:each_proc) { Proc.new { |x, o| } }

    def invoke(enumerator=subject)
      enumerator.each_with_object(object, &each_proc)
    end

    context "when a block is given" do
      let(:each_proc) { Proc.new { |x, o| } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:output)     { {} }
        expect_output!
      end

      context "when the block operates on the object (distinct assignment)" do
        let(:each_proc) { Proc.new { |x, o| o[x.to_i] = x.to_i + 1 } }
        let(:output)    { enumerable.each_with_object({}, &each_proc) }
        expect_output!
      end

      context "when the block operates on the object (replacement)" do
        let(:each_proc) { Proc.new { |x, o| o[0] = x.to_i + 1 } }
        let(:output)    { { 0 => count } }
        expect_output!
      end

      context "with an instrumented each_proc" do
        let(:each_proc) { Proc.new { |x, o| captured << [x, o]; ret_val } }
        let(:ret_val)   { nil }
        let(:captured)  { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
        end

        it "invokes the block once with each element and index" do
          invoke
          captured.zip(enumerable).each_with_index do |(obj, element), index|
            expect(obj.first).to eql(element)
            expect(obj.last).to eql(object)
          end
        end
      end
    end

    context "when a block is not given" do
      let(:each_proc) { nil }

      it "returns an enumerator" do
        expect(invoke).to be_an_instance_of(Xe::Enumerator)
      end

      it "returns an enumerator of equal length" do
        expect(invoke.to_a.length).to eq(count)
      end

      it "returns an enumerator that yields a sequence of (el, obj) pairs" do
        results = invoke.to_a
        expect(results.map(&:first)).to eq(enumerable)
        expect(results.map(&:last)).to eq([object] * count)
      end
    end

  end

  describe '#include?' do

    let(:object) { nil }

    def invoke(enumerator=subject)
      enumerator.include?(object)
    end

    context "when the enumerable includes the object" do
      let(:object) { 0 }
      let(:output) { true }
      expect_output!
    end

    context "when the enumerable doesn't include the object" do
      let(:object) { -1 }
      let(:output) { false }
      expect_output!
    end
  end

  describe '#member?' do
    it "is an alias for #inject" do
      expect(subject.method(:member?)).to eq(subject.method(:include?))
    end
  end

  describe '#select' do

    let(:select_proc) { Proc.new { |x| !!x; true } }

    def invoke(enumerator=subject)
      enumerator.select(&select_proc)
    end

    context "when a block is given" do
      let(:select_proc) { Proc.new { |x| !!x; true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:output)   { [] }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:select_proc) { Proc.new { |x| !!x; true } }
        let(:output)      { enumerable }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:select_proc) { Proc.new { |x| !!x; false } }
        let(:output)      { [] }
        expect_output!
      end

      context "when some invocations of the block return false" do
        let(:select_proc) { Proc.new { |x| x % 3 == 0 } }
        let(:output)      { enumerable.select(&select_proc) }
        expect_output!
      end

      context "with an instrumented select_proc" do
        let(:select_proc) { Proc.new { |x| captured << x; ret_val } }
        let(:ret_val)     { true }
        let(:captured)    { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
      let(:select_proc) { nil }

      it "returns a reference to the enumerator" do
        expect(invoke).to eql(subject)
      end
    end

  end

  describe '#reject' do

    let(:reject_proc) { Proc.new { |x| !!x; true } }

    def invoke(enumerator=subject)
      enumerator.reject(&reject_proc)
    end

    context "when a block is given" do
      let(:reject_proc) { Proc.new { |x| !!x; true } }

      context "when the enumerable is empty" do
        let(:enumerable) { [] }
        let(:output)   { [] }
        expect_output!
      end

      context "when all invocations of the block return true" do
        let(:reject_proc) { Proc.new { |x| !!x; true } }
        let(:output)      { [] }
        expect_output!
      end

      context "when all invocations of the block return false" do
        let(:reject_proc) { Proc.new { |x| !!x; false } }
        let(:output)      { enumerable }
        expect_output!
      end

      context "when some invocations of the block return false" do
        let(:reject_proc) { Proc.new { |x| x % 3 == 0 } }
        let(:output)      { enumerable.reject(&reject_proc) }
        expect_output!
      end

      context "with an instrumented select_proc" do
        let(:reject_proc) { Proc.new { |x| captured << x; ret_val } }
        let(:ret_val)     { true }
        let(:captured)    { [] }

        it "invokes the block once for each element" do
          invoke
          expect(captured.length).to eq(count)
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
      let(:reject_proc) { nil }

      it "returns a reference to the enumerator" do
        expect(invoke).to eql(subject)
      end
    end

  end

end
