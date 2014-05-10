require 'spec_helper'

describe Xe::Target do

  subject { Xe::Target.new(source, id, group_key) }

  let(:source)    { Xe::Deferrable.new }
  let(:id)        { 0 }
  let(:group_key) { 1 }

  describe '#initialize' do

    it "sets the source attribute" do
      expect(subject.source).to eq(source)
    end

    it "sets the id attribute" do
      expect(subject.id).to eq(id)
    end

    it "sets the group_key attribute" do
      expect(subject.group_key).to eq(group_key)
    end

  end

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

  describe '(immutability)' do

    it "doesn't respond to the #[]= method" do
      expect { subject[:key] = 1 }.to raise_error(NoMethodError)
    end

    it "doesn't respond to attribute writer methods" do
      subject.members.each do |member|
        expect { subject.send("member=", 1) }.to raise_error(NoMethodError)
      end
    end

  end

end
