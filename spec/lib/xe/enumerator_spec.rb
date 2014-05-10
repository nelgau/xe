require 'spec_helper'

describe Xe::Enumerator do

  subject { Xe::Enumerator.new(enumerable, options) }

  let(:enumerable) { [1, 2, 3] }
  let(:options) { {} }

  describe '#inspect' do

    it "is a string" do
      expect(subject.inspect).to be_an_instance_of(String)
    end

  end

  describe '#to_s' do

    it "is a string" do
      expect(subject.to_s).to be_an_instance_of(String)
    end

  end

end
