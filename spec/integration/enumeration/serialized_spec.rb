require 'spec_helper'

describe 'Xe - Enumeration (Serialized)' do
  include Xe::Test::Scenario

  let(:scenario_options) { {
    :serialized     => { :enabled    => false },
    :one_fiber      => { :max_fibers => 1     },
    :several_fibers => { :max_fibers => 10    },
    :many_fibers    => { :max_fibers => 200   }
  } }

  let(:realizer_count) { 5 }
  let(:realizers) { (0...realizer_count).map { new_realizer } }

  def new_realizer
    Xe.realizer do |xs|
      xs.map { |x| x + 1 }
    end
  end

  def realize_target(realizer, index)
    group_key = realizer.group_key(index)
    target = Xe::Target.new(realizer, index, group_key)
    Xe::Context.current.realize_target(target)
  end

  describe '#each_with_object' do

    let(:input) { (0...realizer_count).to_a }

    context "when fibers are released in contrary order" do
      it "serializes the injection correctly" do
        result = nil

        Xe.context do |c|
          # In serial order, the last write should win.
          result = c.enum(input).each_with_object({}) do |x, o|
            o[:foo] = realizers[x][x]
          end

          # Realize the targets in reverse order.
          (0...realizer_count).to_a.reverse.each do |index|
            realizer = realizers[index]
            realize_target(realizer, index)
          end

          # Expect no more realizations to occur.
          realizers.each do |realizer|
            expect(realizer).to_not receive(:call)
          end
        end

        # The value of the ':foo' key should be (last index + 1).
        expect(result[:foo]).to eq(realizer_count)
      end
    end

  end

end
