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

    it "realizes" do
      result = Xe.context { Xe.map(input) { |x| x } }
      expect(result).to eq(output)
    end

    it "realizes the values in the largest possible event" do
      result = Xe.context { Xe.map(input) { |x| x } }
      expect(event_tracer.events.length).to eq(1)
      expect(event_tracer.events[0].length).to eq(count)
    end
  end

  context "when choosing between two realizations at the same depth" do
    let(:count1) { 10 }
    let(:count2) { 20 }
    let(:total)  { count1 + count2 }

    let(:group1)  { (0...    count1).map { |i| realizers[0][i] } }
    let(:group2)  { (count1...total).map { |i| realizers[1][i] } }

    let(:input)  { group1 + group2 }
    let(:output) { (0...(count1 + count2)).to_a }

    it "realizes" do
      result = Xe.map(input) { |x| x }
      expect(result).to eq(output)
    end

    it "realizes both events" do
      Xe.context { Xe.map(input) { |x| x } }
      expect(event_tracer.events.length).to eq(2)
    end

    it "chooses the smaller realization first" do
      Xe.context { Xe.map(input) { |x| x } }
      expect(event_tracer.events[0].deferrable).to eq(realizers[0])
      expect(event_tracer.events[0].length).to eq(count1)
    end

    it "chooses the larger realization last" do
      Xe.context { Xe.map(input) { |x| x } }
      expect(event_tracer.events[1].deferrable).to eq(realizers[1])
      expect(event_tracer.events[1].length).to eq(count2)
    end
  end

end
