require 'spec_helper'

describe "Xe - Enumeration (General)" do
  include Xe::Test::Scenario

  let(:scenario_options) { {
    :serialized     => { :enabled    => false },
    # The 'nested' tests require at least three fibers to prevent deadlock.
    :three_fibers   => { :max_fibers => 3     },
    :several_fibers => { :max_fibers => 10    },
    :many_fibers    => { :max_fibers => 200   }
  } }

  let(:realizer_value) do
    Xe.realizer do |xs|
      xs.map { |x| x + 1 }
    end
  end

  let(:realizer_defer) do
    Xe.realizer do |xs|
      xs.map { |x| realizer_value[x] }
    end
  end

  before do
    # Disallow any explicit finalization of the context by a enumerator proxy.
    expect_any_instance_of(Xe::Context).to_not receive(:finalize_by_proxy!)
  end

  #
  # Contexts
  #

  context "when creating a context" do

    context "using 'Xe.context'" do
      expect_consistent!

      def invoke
        Xe.context do |c|
        end
      end
    end

    context "using 'Xe.context' (raises)" do
      expect_exception!

      def invoke
        Xe.context do |c|
          raise_exception
        end
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
          Xe.context do |c|
            c.enum(input).first
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
            Xe.context do |c|
              c.enum(input).all?
            end
          end
        end

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                x > 0
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (always true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                realizer_value[x] > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
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
            Xe.context do |c|
              c.enum(input).all?
            end
          end
        end

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                x > 0
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (always true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                realizer_value[x] > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).all? do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all?
              end
            end
          end
        end

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all? do |x|
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { [false, true, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (always true)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all? do |x|
                  realizer_value[x] > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { [true, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).all? do |x|
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
            Xe.context do |c|
              c.enum(input).any?
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
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
            Xe.context do |c|
              c.enum(input).any?
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).any? do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any?
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { [false, true, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any? do |x|
                  x < 0
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { [true, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any? do |x|
                  realizer_value[x] < 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).any? do |x|
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
            Xe.context do |c|
              c.enum(input).none?
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
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
            Xe.context do |c|
              c.enum(input).none?
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).none? do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none?
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { [true, false, true] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none? do |x|
                  x < 0
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { [false, true, true] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { [true, true, true] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none? do |x|
                  realizer_value[x] < 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).none? do |x|
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
            Xe.context do |c|
              c.enum(input).count
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
                raise_exception if x == 2
                x == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
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
            Xe.context do |c|
              c.enum(input).count
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
                raise_exception if x == 2
                x == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { 1 }

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).count do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).count
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { [0, 1, 0] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).count do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).count do |x|
                  raise_exception if x == 2
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { [1, 0, 0] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).count do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).count do |x|
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
            Xe.context do |c|
              c.enum(input).one?
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
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
            Xe.context do |c|
              c.enum(input).one?
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                x == 3
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                x < 0
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                raise_exception if x == 2
                x > 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { true }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                realizer_value[x] == 3
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
                realizer_value[x] < 0
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).one? do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one?
              end
            end
          end
        end

        context "with a predicate (once true)" do
          expect_output!

          let(:output) { [false, true, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one? do |x|
                  x == 3
                end
              end
            end
          end
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one? do |x|
                  x < 0
                end
              end
            end
          end
        end

        context "with a predicate (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one? do |x|
                  raise_exception if x == 2
                  x > 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (once true)" do
          expect_output!

          let(:output) { [true, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one? do |x|
                  realizer_value[x] == 3
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (never true)" do
          expect_output!

          let(:output) { [false, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one? do |x|
                  realizer_value[x] < 0
                end
              end
            end
          end
        end

        context "with a predicate that defers a realization (raises)" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).one? do |x|
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
            Xe.context do |c|
              c.enum(input).include?(value)
            end
          end
        end

        context "when the array doesn't include the value" do
          expect_output!

          let(:value)  { 0 }
          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).include?(value)
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
            Xe.context do |c|
              c.enum(input).include?(value)
            end
          end
        end

        context "when the array doesn't include the value" do
          expect_output!

          let(:value)  { 1 }
          let(:output) { false }

          def invoke
            Xe.context do |c|
              c.enum(input).include?(value)
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).include?(value)
              end
            end
          end
        end

        context "when the array doesn't include the value" do
          expect_output!

          let(:value)  { 0 }
          let(:output) { [false, false, false] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).include?(value)
              end
            end
          end
        end
      end

    end

  end

  #
  # Iterating Enumeration
  #

  context "with an interating enumerator" do

    describe '#each' do

      context "when called without a block" do
        let(:input) { [1, 2, 3] }

        it "returns an instance of Xe::Enumerator" do
          result = Xe.context { |c| c.enum(input).each }
          expect(result).to be_an_instance_of(Xe::Enumerator)
        end

        it "returns an enumerator that enumerates the collection" do
          result = Xe.context { |c| c.enum(input).each.to_a }
          expect(result).to eq(input)
        end
      end

      context "with an array of values" do
        let(:input) { [1, 2, 3] }

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [1, 2, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).each do |x|
                x.to_i
              end
            end
          end
        end

        context "when capturing the block's argument" do
          expect_output!

          let(:output) { [1, 2, 3] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each do |x|
                captured << x
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |x|
                raise_exception if x == 2
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).each do |x|
                x.to_i
              end
            end
          end
        end

        context "when capturing the block's argument" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each do |x|
                captured << x
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |x|
                raise_exception if x == 2
              end
            end
          end
        end
      end

      context "with an array of realized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).each do |x|
                x.to_i
              end
            end
          end
        end

        context "when capturing the block's argument" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each do |x|
                captured << x.to_i
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |x|
                raise_exception if x == 2
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  x.to_i
                end
              end
            end
          end
        end

        context "when capturing the block's arguments" do
          expect_output!

          let(:output) { [1, 2, 3, 4, 5, 6, 7, 8, 9] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  captured << x
                end
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  raise_exception if x == 2
                end
              end
            end
          end
        end
      end

      context "with an array of unrealized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [[2, 3, 4], [5, 6, 7], [8, 9, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  x.to_i
                end
              end
            end
          end
        end

        context "when capturing the block's arguments" do
          expect_output!

          let(:output) { [2, 3, 4, 5, 6, 7, 8, 9, 10] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  captured << x
                end
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  raise_exception if x == 2
                end
              end
            end
          end
        end
      end

      context "with an array of realized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [[2, 3, 4], [5, 6, 7], [8, 9, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  x.to_i
                end
              end
            end
          end
        end

        context "when capturing the block's arguments" do
          expect_output!

          let(:output) { [2, 3, 4, 5, 6, 7, 8, 9, 10] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  captured << x.to_i
                end
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  raise_exception if x == 2
                end
              end
            end
          end
        end
      end

    end

    describe '#each_with_index' do

      context "when called without a block" do
        let(:input) { [1, 2, 3] }

        it "returns an instance of Xe::Enumerator" do
          result = Xe.context { |c| c.enum(input).each_with_index }
          expect(result).to be_an_instance_of(Xe::Enumerator)
        end

        it "returns an enumerator that enumerates the collection and index" do
          result = Xe.context { |c| c.enum(input).each_with_index.to_a }
          expected = input.each_with_index.to_a
          expect(result).to eq(expected)
        end
      end

      context "with an array of values" do
        let(:input) { [1, 2, 3] }

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [1, 2, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                x.to_i
              end
            end
          end
        end

        context "when capturing the block's argument" do
          expect_output!

          let(:output) { [[1, 0], [2, 1], [3, 2]] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                captured << [x, i]
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                raise_exception if x == 2
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                x.to_i
              end
            end
          end
        end

        context "when capturing the block's argument" do
          expect_output!

          let(:output) { [[2, 0], [3, 1], [4, 2]] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                captured << [x, i]
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                raise_exception if x == 2
              end
            end
          end
        end
      end

      context "with an array of realized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                x.to_i
              end
            end
          end
        end

        context "when capturing the block's argument" do
          expect_output!

          let(:output) { [[2, 0], [3, 1], [4, 2]] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                captured << [x.to_i, i]
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |x, i|
                raise_exception if x == 2
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  x.to_i
                end
              end
            end
          end
        end

        context "when capturing the block's arguments" do
          expect_output!

          let(:output) { [
            [1, 0, 0],
            [2, 0, 1],
            [3, 0, 2],
            [4, 1, 0],
            [5, 1, 1],
            [6, 1, 2],
            [7, 2, 0],
            [8, 2, 1],
            [9, 2, 2]
          ] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  captured << [x, i1, i2]
                end
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  raise_exception if x == 2
                end
              end
            end
          end
        end
      end

      context "with an array of unrealized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [[2, 3, 4], [5, 6, 7], [8, 9, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  x.to_i
                end
              end
            end
          end
        end

        context "when capturing the block's arguments" do
          expect_output!

          let(:output) { [
            [2,  0, 0],
            [3,  0, 1],
            [4,  0, 2],
            [5,  1, 0],
            [6,  1, 1],
            [7,  1, 2],
            [8,  2, 0],
            [9,  2, 1],
            [10, 2, 2]
          ] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  captured << [x, i1, i2]
                end
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  raise_exception if x == 2
                end
              end
            end
          end
        end
      end

      context "with an array of realized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "when consuming the return value (block given)" do
          expect_output!

          let(:output) { [[2, 3, 4], [5, 6, 7], [8, 9, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  x.to_i
                end
              end
            end
          end
        end

        context "when capturing the block's arguments" do
          expect_output!

          let(:output) { [
            [2,  0, 0],
            [3,  0, 1],
            [4,  0, 2],
            [5,  1, 0],
            [6,  1, 1],
            [7,  1, 2],
            [8,  2, 0],
            [9,  2, 1],
            [10, 2, 2]
          ] }

          def invoke
            captured = []
            Xe.context do |c|
              c.enum(input).each_with_index do |arr, i1|
                c.enum(arr).each_with_index do |x, i2|
                  captured << [x.to_i, i1, i2]
                end
              end
            end
            captured
          end
        end

        context "when the block raises" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each do |arr|
                c.enum(arr).each do |x|
                  raise_exception if x == 2
                end
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
            Xe.context do |c|
              c.enum(input).map do |x|
                x + 1
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          let(:input)  { [1, 2, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).map do |x|
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
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |x|
              realizer_value[x]
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do |c|
            c.enum(input).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |x|
              realizer_value[x].to_i
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do |c|
            c.enum(input).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |x|
              realizer_defer[x]
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do |c|
            c.enum(input).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |x|
              realizer_defer[x].to_i
            end
          end
        end
      end

      context "when raising" do
        expect_exception!

        let(:input)  { [1, 2, 3] }

        def invoke
          Xe.context do |c|
            c.enum(input).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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
          Xe.context do |c|
            c.enum(input).map do |arr|
              c.enum(arr).map do |x|
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

      context "with an array of values" do
        let(:input) { [1, 2, 3] }

        context "when injecting a sum" do
          expect_output!

          let(:output) { 6 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum, x|
                sum + x
              end
            end
          end
        end

        context "when injecting a sum of deferred values" do
          expect_output!

          let(:output) { 9 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum, x|
                sum + realizer_value[x]
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum, x|
                raise_exception if x == 2
                sum + x
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when injecting a sum (coercion)" do
          expect_output!

          let(:output) { 9 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum, x|
                sum + x
              end
            end
          end
        end

        context "when injecting a sum of deferred values" do
          expect_output!

          let(:output) { 12 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum, x|
                sum + realizer_value[x]
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum, x|
                raise_exception if x == 2
                sum + x
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

        context "when injecting a sum" do
          expect_output!

          let(:output) { 45 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum1, arr|
                sum1 + c.enum(arr).inject(0) do |sum2, x|
                  sum2 + x
                end
              end
            end
          end
        end

        context "when injecting a sum of deferred values" do
          expect_output!

          let(:output) { 54 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum1, arr|
                sum1 + c.enum(arr).inject(0) do |sum2, x|
                  sum2 + realizer_value[x]
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum1, arr|
                sum1 + c.enum(arr).inject(0) do |sum2, x|
                  raise_exception if x == 2
                  sum2 + realizer_value[x]
                end
              end
            end
          end
        end
      end

      context "with an array of unrealized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "when injecting a sum" do
          expect_output!

          let(:output) { 54 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum1, arr|
                sum1 + c.enum(arr).inject(0) do |sum2, x|
                  sum2 + x
                end
              end
            end
          end
        end

        context "when injecting a sum of deferred values" do
          expect_output!

          let(:output) { 63 }

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum1, arr|
                sum1 + c.enum(arr).inject(0) do |sum2, x|
                  sum2 + realizer_value[x]
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).inject(0) do |sum1, arr|
                sum1 + c.enum(arr).inject(0) do |sum2, x|
                  raise_exception if x == 2
                  sum2 + realizer_value[x]
                end
              end
            end
          end
        end
      end

    end

    describe '#each_with_object' do

      def new_hash
        Hash.new { |h, k| h[k] = 0 }
      end

      context "when called without a block" do
        let(:input) { [1, 2, 3] }
        let(:obj)   { :foo }

        it "returns an instance of Xe::Enumerator" do
          result = Xe.context { |c| c.enum(input).each_with_object(obj) }
          expect(result).to be_an_instance_of(Xe::Enumerator)
        end

        it "returns an enumerator that enumerates the collection and index" do
          result = Xe.context { |c| c.enum(input).each_with_object(obj).to_a }
          expected = input.each_with_object(obj).to_a
          expect(result).to eq(expected)
        end
      end

      context "with an array of values" do
        let(:input) { [1, 2, 3] }

        context "when incrementing keys in a hash" do
          expect_output!

          let(:output) { { 1 => 1, 2 => 1, 3 => 1 } }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object(new_hash) do |x, o|
                o[x] += 1
              end
            end
          end
        end

        context "when incrementing keys in a hash with a deferred value" do
          expect_output!

          let(:output) { { 1 => 2, 2 => 3, 3 => 4 } }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object(new_hash) do |x, o|
                o[x] += realizer_value[x]
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object(new_hash) do |x, o|
                raise_exception if x == 2
                o[x] += 1
              end
            end
          end
        end

      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "when incrementing keys in a hash" do
          expect_output!

          let(:output) { { 2 => 1, 3 => 1, 4 => 1 } }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object(new_hash) do |x, o|
                o[x] += 1
              end
            end
          end
        end

        context "when incrementing keys in a hash with a deferred value" do
          expect_output!

          let(:output) { { 2 => 3, 3 => 4, 4 => 5 } }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object(new_hash) do |x, o|
                o[x] += realizer_value[x]
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object(new_hash) do |x, o|
                raise_exception if x == 2
                o[x] += 1
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

        context "when incrementing keys in a hash" do
          expect_output!

          let(:output) { [
            { 1 => 1, 2 => 1, 3 => 1 },
            { 4 => 1, 5 => 1, 6 => 1 },
            { 7 => 1, 8 => 1, 9 => 1 },
          ] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object([]) do |arr, o1|
                o1 << c.enum(arr).each_with_object(new_hash) do |x2, o2|
                  o2[x2] += 1
                end
              end
            end
          end
        end

         context "when incrementing keys in a hash with a deferred value" do
          expect_output!

          let(:output) { [
            { 1 => 2, 2 => 3, 3 =>  4 },
            { 4 => 5, 5 => 6, 6 =>  7 },
            { 7 => 8, 8 => 9, 9 => 10 },
          ] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object([]) do |arr, o1|
                o1 << c.enum(arr).each_with_object(new_hash) do |x2, o2|
                  o2[x2] += realizer_value[x2]
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object([]) do |arr, o1|
                o1 << c.enum(arr).each_with_object(new_hash) do |x2, o2|
                  raise_exception if x2 == 2
                  o2[x2] += 1
                end
              end
            end
          end
        end
      end

      context "with an array of unrealized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "when incrementing keys in a hash" do
          expect_output!

          let(:output) { [
            { 2 => 1, 3 => 1,  4 => 1 },
            { 5 => 1, 6 => 1,  7 => 1 },
            { 8 => 1, 9 => 1, 10 => 1 },
          ] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object([]) do |arr, o1|
                o1 << c.enum(arr).each_with_object(new_hash) do |x2, o2|
                  o2[x2] += 1
                end
              end
            end
          end
        end

         context "when incrementing keys in a hash with a deferred value" do
          expect_output!

          let(:output) { [
            { 2 => 3, 3 => 4,   4 =>  5 },
            { 5 => 6, 6 => 7,   7 =>  8 },
            { 8 => 9, 9 => 10, 10 => 11 },
          ] }

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object([]) do |arr, o1|
                o1 << c.enum(arr).each_with_object(new_hash) do |x2, o2|
                  o2[x2] += realizer_value[x2]
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).each_with_object([]) do |arr, o1|
                o1 << c.enum(arr).each_with_object(new_hash) do |x2, o2|
                  raise_exception if x2 == 2
                  o2[x2] += 1
                end
              end
            end
          end
        end
      end

    end

  end

  #
  # Filtering Enumeration
  #

  context "with a filtering enumerator" do

    describe '#select' do

      context "when called without a block" do
        let(:input) { [1, 2, 3] }

        it "returns an instance of Xe::Enumerator" do
          result = Xe.context { |c| c.enum(input).select }
          expect(result).to be_an_instance_of(Xe::Enumerator)
        end

        it "returns an enumerator that enumerates the collection" do
          result = Xe.context { |c| c.enum(input).select.to_a }
          expect(result).to eq(input)
        end
      end

      context "with an array of values" do
        let(:input) { [1, 2, 3] }

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { [1, 2, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                !!x || true
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [2] }

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                x % 2 == 0
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [1, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                realizer_value[x] % 2 == 0
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                raise_exception if x == 2
                !!x || true
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                !!x || true
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [2, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                x % 2 == 0
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [3] }

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                realizer_value[x] % 2 == 0
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).select do |x|
                raise_exception if x == 2
                !!x || true
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  !!x || true
                end
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [[2], [4, 6], [8]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  x % 2 == 0
                end
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [[1, 3], [5], [7, 9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  realizer_value[x] % 2 == 0
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  raise_exception if x == 2
                  !!x || true
                end
              end
            end
          end
        end
      end

      context "with an array of unrealized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { [[2, 3, 4], [5, 6, 7], [8, 9, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  !!x || true
                end
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [[2, 4], [6], [8, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  x % 2 == 0
                end
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [[3], [5, 7], [9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  realizer_value[x] % 2 == 0
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).select do |x|
                  raise_exception if x == 2
                  !!x || true
                end
              end
            end
          end
        end
      end

    end

    describe '#reject' do

     context "when called without a block" do
        let(:input) { [1, 2, 3] }

        it "returns an instance of Xe::Enumerator" do
          result = Xe.context { |c| c.enum(input).reject }
          expect(result).to be_an_instance_of(Xe::Enumerator)
        end

        it "returns an enumerator that enumerates the collection" do
          result = Xe.context { |c| c.enum(input).reject.to_a }
          expect(result).to eq(input)
        end
      end

      context "with an array of values" do
        let(:input) { [1, 2, 3] }

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { [1, 2, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                !!x && false
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [1, 3] }

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                x % 2 == 0
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [2] }

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                realizer_value[x] % 2 == 0
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                raise_exception if x == 2
                !!x && false
              end
            end
          end
        end
      end

      context "with an array of unrealized values" do
        let(:input) do
          [1, 2, 3].map { |x| realizer_value[x] }
        end

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { [2, 3, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                !!x && false
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [3] }

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                x % 2 == 0
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [2, 4] }

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                realizer_value[x] % 2 == 0
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).reject do |x|
                raise_exception if x == 2
                !!x && false
              end
            end
          end
        end
      end

      context "with an array of values (nested)" do
        let(:input) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

        context "with a predicate (never true)" do
          expect_output!

          let(:output) { [[1, 2, 3], [4, 5, 6], [7, 8, 9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  !!x && false
                end
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [[1, 3], [5], [7, 9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  x % 2 == 0
                end
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [[2], [4, 6], [8]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  realizer_value[x] % 2 == 0
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  raise_exception if x == 2
                  !!x && false
                end
              end
            end
          end
        end
      end

      context "with an array of unrealized values (nested)" do
        let(:input) do
          ids = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
          ids.map { |arr| arr.map { |x| realizer_value[x] } }
        end

        context "with a predicate (always true)" do
          expect_output!

          let(:output) { [[2, 3, 4], [5, 6, 7], [8, 9, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  !!x && false
                end
              end
            end
          end
        end

        context "with a predicate (true for even values)" do
          expect_output!

          let(:output) { [[3], [5, 7], [9]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  x % 2 == 0
                end
              end
            end
          end
        end

        context "with a predicate (true for even, deferred values)" do
          expect_output!

          let(:output) { [[2, 4], [6], [8, 10]] }

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  realizer_value[x] % 2 == 0
                end
              end
            end
          end
        end

        context "when raising" do
          expect_exception!

          def invoke
            Xe.context do |c|
              c.enum(input).map do |arr|
                c.enum(arr).reject do |x|
                  raise_exception if x == 2
                  !!x && false
                end
              end
            end
          end
        end
      end

    end

  end

end
