require 'spec_helper'

describe "Xe - Realization Order" do

  let(:event_tracer)   { Xe::Tracer::Event.new }

  let(:realizer_count) { 5 }
  let(:realizers) do
    (0...realizer_count).map do |index|
      # Construct a set of trivial realizers.
      Xe.realizer { |group| group }
    end
  end

  around do |example|
    Xe.config.tracer = event_tracer
    example.run
    Xe.config.tracer = nil
  end

  context "when realizing flat, homogeneous values" do
    let(:count)  { 30 }
    let(:input)  { (0...count).map { |i| realizers[0][i] } }
    let(:output) { (0...count).to_a }

    def invoke
      Xe.context { Xe.map(input) { |x| x } }
    end

    it "realizes" do
      expect(invoke).to eq(output)
    end

    it "realizes the values in the largest possible event" do
      invoke
      expect(event_tracer.events.length).to eq(1)
      expect(event_tracer.events[0].length).to eq(count)
    end
  end

  context "when selecting between two realizations at the same depth" do
    let(:count1) { 10 }
    let(:count2) { 20 }
    let(:total)  { count1 + count2 }

    let(:group1)  { (0...    count1).map { |i| realizers[0][i] } }
    let(:group2)  { (count1...total).map { |i| realizers[1][i] } }

    let(:input)  { group1 + group2 }
    let(:output) { (0...(count1 + count2)).to_a }

    def invoke
      Xe.context { Xe.map(input) { |x| x } }
    end

    it "realizes" do
      expect(invoke).to eq(output)
    end

    it "realizes both events" do
      invoke
      expect(event_tracer.events.length).to eq(2)
    end

    it "selects the smaller realization first" do
      invoke
      expect(event_tracer.events[0].deferrable).to eq(realizers[0])
      expect(event_tracer.events[0].length).to eq(count1)
    end

    it "selects the larger realization last" do
      invoke
      expect(event_tracer.events[1].deferrable).to eq(realizers[1])
      expect(event_tracer.events[1].length).to eq(count2)
    end
  end

  context "when selecting between realizations at different wait depths" do
    context "when all group sizes are equal" do

      let(:id_count)     { 10 }
      let(:group2_count) { realizer_count - 1 }

      let(:input1) do
        (0...id_count).map { |i| realizers[0][i] }
      end

      let(:input2) do
        (0...group2_count).map do |ri|
          (0...id_count).map { |i| realizers[ri + 1][i] }
        end
      end

      def invoke
        Xe.context do
          Xe.map(input1) { |x| x.to_i }
          Xe.map(input2) { |j| Xe.map(j) { |x| x.to_i } }
        end
      end

      it "realizes all events" do
        invoke
        expect(event_tracer.events.length).to eq(realizer_count)
      end

      it "selecting the shallowest realization first" do
        invoke
        expect(event_tracer.events[0].deferrable).to eq(realizers[0])
        expect(event_tracer.events[0].length).to eq(id_count)
      end
    end
  end

end
