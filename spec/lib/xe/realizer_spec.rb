require 'spec_helper'

describe Xe::Realizer do

  subject { Xe::Realizer }

  describe '.new' do

    it "returns a new block realizer" do
      expect(subject.new {}).to be_an_instance_of(Xe::Realizer::Proc)
    end

    it "returns a new realize with an identical proc" do
      realize_proc = Proc.new { puts "A" }
      realizer = subject.new(&realize_proc)
      expect(realizer.realize_proc).to eq(realize_proc)
    end

  end

end
