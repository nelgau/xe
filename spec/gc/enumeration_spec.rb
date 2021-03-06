require 'spec_helper'

describe "Xe - Garbage Collection (Enumeration)" do
  include Xe::Test::GC

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
      define_test! has_output: false

      def invoke
        Xe.context {}
      end
    end

    context "using 'Xe.context' (raises)" do
      define_test_with_exception!

      def invoke
        Xe.context { raise_exception }
      end
    end
  end

  #
  # Single-Valued Enumeration
  #

  context "with a single-valued enumerator" do

    context "with #first" do
      define_test!

      let(:input)  { [1, 2, 3] }
      let(:output) { 1 }

      def invoke
        Xe.context do
          Xe.enum(input).first
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
          define_test!

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
          define_test_with_exception!

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
          define_test!

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
          define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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
  # Realization Outside of an Enumerator
  #

  context "when realizing outside of an enumerator" do

    context "when a single-valued enumerator" do

      context "when returning values" do
        define_test!

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
        define_test_with_exception!

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
        define_test!

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
        define_test_with_exception!

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

  #
  # Injecting Enumeration
  #

  context "with an injecting enumerator" do

    context "with #inject" do
      context "and realized values (coercion)" do
        define_test!

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
        define_test!

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
        define_test_with_exception!

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

end
