require 'spec_helper'

describe "Xe - Enumeration" do
  include Xe::Test::Scenario

  let(:scenario_options) { {
    :serialized     => { :enabled    => false },
    # The 'nested' tests require at least three fibers to prevent deadlock.
    :two_fibers     => { :max_fibers => 3     },
    :several_fibers => { :max_fibers => 10    },
    :many_fibers    => { :max_fibers => 200   }
  } }

  let(:realizer_value) do
    Xe.realizer do |xs|
      xs.each_with_object({}) do |x, rs|
        rs[x] = x + 1
      end
    end
  end

  let(:realizer_defer) do
    Xe.realizer do |xs|
      xs.each_with_object({}) do |x, rs|
        rs[x] = realizer_value[x]
      end
    end
  end

  #
  # Contexts
  #

  context "when creating a context" do

    context "using 'Xe.context'" do
      expect_consistent!

      def invoke
        Xe.context {}
      end
    end

    context "using 'Xe.context' (raises)" do
      expect_exception!

      def invoke
        Xe.context { raise_exception }
      end
    end
  end

  #
  # Evaluated Enumeration
  #

  context "with an evaluated enumerator" do

    describe "#first" do

      let(:input)  { [1, 2, 3] }

      context "with an array of values" do
        expect_output!

        let(:output) { 1 }

        def invoke
          Xe.context do
            Xe.enum(input).first
          end
        end
      end

    end

  end

  #
  # Single-Valued Enumeration
  #

  context "with a single-valued enumerator" do

    describe '#all?' do

      context "with an array of values" do
        let(:input)  { [1, 2, 3] }

        context "with no predicate" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).all?
            end
          end
        end

        context "with a predicate (never false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                x > 0
              end
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (never false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                realizer_value[x] > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with no predicate" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).all?
            end
          end
        end

        context "with a predicate (never false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                x > 0
              end
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (never false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                realizer_value[x] > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).all? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input)  { [[2], [3], [4, 5, 6]] }

        context "with no predicate" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all?
              end
            end
          end
        end

        context "with a predicate (never false)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all? do |x|
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { [false, true, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (never false)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all? do |x|
                  realizer_value[x] > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { [true, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).all? do |x|
                  raise_exception if x == 2
                  realizer_value[x] > 0
                end
              end
            end
          end
        end
      end

    end

    describe '#any?' do

      context "with an array of values" do
        let(:input)  { [1, 2, 3] }

        context "with no predicate" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).any?
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with no predicate" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).any?
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).any? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input)  { [[1, 2], [3], [5, 6]] }

        context "with no predicate" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any?
              end
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { [false, true, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any? do |x|
                  x < 0
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { [true, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any? do |x|
                  realizer_value[x] < 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).any? do |x|
                  raise_exception if x == 2
                  realizer_value[x] > 0
                end
              end
            end
          end
        end
      end

    end

    describe '#none?' do

      context "with an array of values" do
        let(:input)  { [1, 2, 3] }

        context "with no predicate" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).none?
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with no predicate" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).none?
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).none? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input)  { [[1, 2], [3], [5, 6]] }

        context "with no predicate" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none?
              end
            end
          end
        end

        context "with a predicate (false)" do
          expect_output!

          let(:output) { [true, false, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none? do |x|
                  x < 0
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (false)" do
          expect_output!

          let(:output) { [false, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none? do |x|
                  realizer_value[x] < 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).none? do |x|
                  raise_exception if x == 2
                  realizer_value[x] > 0
                end
              end
            end
          end
        end
      end

    end

    describe "#count" do

      context "with an array of values" do
        let(:input)  { [1, 2, 3] }

        context "with no predicate" do
          expect_output!

          let(:output) { 3 }

          def invoke
            Xe.context do
              Xe.enum(input).count
            end
          end
        end

        context "with a predicate" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                raise_exception if x == 2
                x == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                raise_exception if x == 2
                realizer_value[x] == 3
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with no predicate" do
          expect_output!

          let(:output) { 3 }

          def invoke
            Xe.context do
              Xe.enum(input).count
            end
          end
        end

        context "with a predicate" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                raise_exception if x == 2
                x == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).count do |x|
                raise_exception if x == 2
                realizer_value[x] == 3
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input)  { [[1, 2], [3, 4, 5], [6]] }

        context "with no predicate" do
          expect_output!

          let(:output) { [2, 3, 1] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).count
              end
            end
          end
        end

        context "with a predicate" do
          expect_output!

          let(:output) { [0, 1, 0] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).count do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).count do |x|
                  raise_exception if x == 2
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization" do
          expect_output!

          let(:output) { [1, 0, 0] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).count do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).count do |x|
                  raise_exception if x == 2
                  realizer_value[x] == 3
                end
              end
            end
          end
        end
      end

    end

    describe '#one?' do

      context "with an array of values" do
        let(:input)  { [1, 2, 3] }

        context "with no predicate" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).one?
            end
          end
        end

        context "with a predicate (true once)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (true once)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with no predicate" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).one?
            end
          end
        end

        context "with a predicate (true once)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (true once)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.enum(input).one? do |x|
                raise_exception if x == 2
                realizer_value[x] > 0
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input)  { [[2], [3, 4], [5]] }

        context "with no predicate" do
          expect_output!

          let(:output) { [true, false, true] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one?
              end
            end
          end
        end

        context "with a predicate (true once)" do
          expect_output!

          let(:output) { [false, true, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (always false)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one? do |x|
                  x < 0
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (true once)" do
          expect_output!

          let(:output) { [true, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (always false)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one? do |x|
                  realizer_value[x] < 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).one? do |x|
                  raise_exception if x == 2
                  realizer_value[x] > 0
                end
              end
            end
          end
        end
      end

    end

    describe '#include?' do

     context "with an array of values" do
        let(:input)  { [1, 2, 3] }

        context "when the array includes the value" do
          expect_output!

          let(:value)  { 2 }
          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).include?(value)
            end
          end
        end

        context "when the array doesn't include the value" do
          expect_output!

          let(:value)  { 0 }
          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).include?(value)
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when the array includes the value" do
          expect_output!

          let(:value)  { 4 }
          let(:output) { true }

          def invoke
            Xe.context do
              Xe.enum(input).include?(value)
            end
          end
        end

        context "when the array doesn't include the value" do
          expect_output!

          let(:value)  { 1 }
          let(:output) { false }

          def invoke
            Xe.context do
              Xe.enum(input).include?(value)
            end
          end
        end
      end

     context "with an array of values (nested)" do
        let(:input)  { [[1], [2, 3, 4], [5, 6]] }

        context "when the array includes the value" do
          expect_output!

          let(:value)  { 2 }
          let(:output) { [false, true, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).include?(value)
              end
            end
          end
        end

        context "when the array doesn't include the value" do
          expect_output!

          let(:value)  { 0 }
          let(:output) { [false, false, false] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.enum(arr).include?(value)
              end
            end
          end
        end
      end

    end

  end

  #
  # Mapping Enumeration
  #

  context "with a mapping enumerator" do

    context "with #map" do

      context "for values to values" do

        context "when returing values" do
          expect_output!

          let(:input)  { [1, 2, 3] }
          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do
              Xe.map(input) do |x|
                x + 1
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          let(:input)  { [1, 2, 3] }

          def invoke
            Xe.context do
              Xe.map(input) do |x|
                raise_exception if x == 2
                x + 1
              end
            end
          end
        end

        context "when returning values (nested)" do
          expect_output!

          let(:input)  { [[1, 2], [3, 4], [5, 6]] }
          let(:output) { [[2, 3], [4, 5], [6, 7]] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.map(arr) do |x|
                  x + 1
                end
              end
            end
          end
        end

        context "when raising (nested)" do
          expect_exception!

          let(:input)  { [[1, 2], [3, 4], [5, 6]] }

          def invoke
            Xe.context do
              Xe.map(input) do |arr|
                Xe.map(arr) do |x|
                  raise_exception if x == 2
                  x + 1
                end
              end
            end
          end
        end
      end
    end

    context "for values to unrealized values" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { [2, 3, 4] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              realizer_value[x]
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              raise_exception if x == 2
              realizer_value[x]
            end
          end
        end
      end

      context "when returning values (nested)" do
        expect_output!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }
        let(:output) { [[2, 3], [4, 5], [6, 7]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                realizer_value[x]
              end
            end
          end
        end
      end

      context "when raising (nested)" do
        expect_exception!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                raise_exception if x == 2
                realizer_value[x]
              end
            end
          end
        end
      end
    end

    context "for values to realized values (explicit)" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { [2, 3, 4] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              realizer_value[x].to_i
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              raise_exception if x == 2
              realizer_value[x].to_i
            end
          end
        end
      end

      context "when returning values (nested)" do
        expect_output!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }
        let(:output) { [[2, 3], [4, 5], [6, 7]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                realizer_value[x].to_i
              end
            end
          end
        end
      end


      context "when raising (nested)" do
        expect_exception!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                raise_exception if x == 2
                realizer_value[x].to_i
              end
            end
          end
        end
      end
    end

    context "for values to deferred unrealized values" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { [2, 3, 4] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              realizer_defer[x]
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              raise_exception if x == 2
              realizer_defer[x]
            end
          end
        end
      end

      context "when returning values (nested)" do
        expect_output!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }
        let(:output) { [[2, 3], [4, 5], [6, 7]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                realizer_defer[x]
              end
            end
          end
        end
      end

      context "when raising (nested)" do
        expect_exception!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                raise_exception if x == 2
                realizer_defer[x]
              end
            end
          end
        end
      end
    end

    context "for values to deferred realized values" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { [2, 3, 4] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              realizer_defer[x].to_i
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do
            Xe.map(input) do |x|
              raise_exception if x == 2
              realizer_defer[x].to_i
            end
          end
        end
      end

      context "when returning values (nested)" do
        expect_output!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }
        let(:output) { [[2, 3], [4, 5], [6, 7]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                realizer_defer[x].to_i
              end
            end
          end
        end
      end

      context "when raising (nested)" do
        expect_exception!

        let(:input)  { [[1, 2], [3, 4], [5, 6]] }

        def invoke
          Xe.context do
            Xe.map(input) do |arr|
              Xe.map(arr) do |x|
                raise_exception if x == 2
                realizer_defer[x].to_i
              end
            end
          end
        end
      end

    end

  end

  #
  # Injecting Enumeration
  #

  context "with an injecting enumerator" do

    context "with #inject" do
      context "and realized values (coercion)" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { 6 }

        def invoke
          Xe.context do
            Xe.enum(input).inject(0) do |sum, x|
              sum + x
            end
          end
        end
      end

      context "and realized values (explicit)" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { 9 }

        def invoke
          Xe.context do
            Xe.enum(input).inject(0) do |sum, x|
              sum + realizer_value[x].to_i
            end
          end
        end
      end

      context "and realized values (raises)" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do
            Xe.enum(input).inject(0) do |sum, x|
              raise_exception if x == 2
              sum + realizer_value[x].to_i
            end
          end
        end
      end
    end

  end

  #
  # Realization Outside of an Enumerator
  #

  context "when realizing outside of an enumerator" do

    context "when a single-valued enumerator" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { 9 }

        def invoke
          Xe.context do
            result = Xe.enum(input).inject(0) do |sum, x|
              sum + realizer_value[x]
            end
            result.to_i
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input) { [1, 2, 3] }

        def invoke
          Xe.context do
            result = Xe.enum(input).inject(0) do |sum, x|
              raise_exception if x == 2
              sum + realizer_value[x]
            end
            result.to_i
          end
        end
      end
    end

    context "with a mapping enumerator" do
      context "when returning values" do
        expect_output!

        let(:input)  { [1, 2, 3] }
        let(:output) { [2, 3, 4] }

        def invoke
          Xe.context do
            result = Xe.map(input) do |x|
              realizer_value[x]
            end
            result.map do |x|
              x.to_i
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input) { [1, 2, 3] }

        def invoke
          Xe.context do
            result = Xe.map(input) do |x|
              raise_exception if x == 2
              realizer_value[x]
            end
            result.map do |x|
              x.to_i
            end
          end
        end
      end
    end

  end

end
