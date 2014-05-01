require 'spec_helper'

describe Xe::Deferrable do

  describe '#call' do

    it "is a hash" do
      expect(subject.call([0])).to be_an_instance_of(Hash)
    end

    it "is empty" do
      expect(subject.call([0])).to be_empty
    end
  end

  describe '#group_key' do

    it "is nil" do
      expect(subject.group_key(0)).to be_nil
    end

  end

  describe '#new_group' do

    it "is not nil" do
      expect(subject.new_group(0)).to_not be_nil
    end

    it "is enumerable" do
      group = subject.new_group(0)
      expect(group.class.ancestors).to include(Enumerable)
    end

    it "responds to #each" do
      group = subject.new_group(0)
      expect(group.respond_to?(:each)).to be_true
    end

    it "responds to #<<" do
      group = subject.new_group(0)
      expect(group.respond_to?(:<<)).to be_true
    end

  end

end
