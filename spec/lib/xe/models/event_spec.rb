require 'spec_helper'

describe Xe::Event do

  subject { Xe::Event.new(deferrable, group_key) }

  let(:deferrable) { Xe::Deferrable.new }
  let(:group_key)  { 1 }

  describe '.from_target' do

    let(:source) { deferrable }
    let(:target) { Xe::Target.new(source, 0, group_key) }

    context "when the target's source is a deferrable" do
      let(:source) { deferrable }

      it "returns an event" do
        event = Xe::Event.from_target(target)
        expect(event).to be_an_instance_of(Xe::Event)
      end

      it "returns an event with the correct deferrable" do
        event = Xe::Event.from_target(target)
        expect(event.deferrable).to eq(deferrable)
      end

      it "returns an event with the correct group key" do
        event = Xe::Event.from_target(target)
        expect(event.group_key).to eq(group_key)
      end
    end

    context "when the target's source isn't a deferrable" do
      let(:source) { double('Not Deferrable') }

      it "raises Xe::DeferError" do
        expect { Xe::Event.from_target(target) }.to raise_error(Xe::DeferError)
      end

    end

  end

  describe '.key' do

    it "is an array" do
      key = Xe::Event.key(deferrable, group_key)
      expect(key).to be_an_instance_of(Array)
    end

    it "is a pair of deferrable and group_key" do
      key = Xe::Event.key(deferrable, group_key)
      expect(key[0]).to eq(deferrable)
      expect(key[1]).to eq(group_key)
    end

  end

  describe '.target_key' do

    let(:source) { deferrable }
    let(:target) { Xe::Target.new(source, 0, group_key) }

    it "is an array" do
      key = Xe::Event.target_key(target)
      expect(key).to be_an_instance_of(Array)
    end

    it "is a pair of deferrable and group_key" do
      key = Xe::Event.target_key(target)
      expect(key[0]).to eq(deferrable)
      expect(key[1]).to eq(group_key)
    end

  end

  describe '#initialize' do

    it "sets the deferrable attribute" do
      expect(subject.deferrable).to eq(deferrable)
    end

    it "sets the group_key attribute" do
      expect(subject.group_key).to eq(group_key)
    end

    it "returns an event with an instance of the deferrable's group" do
      group = Set.new
      deferrable.stub(:new_group) { group }
      expect(subject.group).to eq(group)
    end

    it "returns an event with a key" do
      key = Xe::Event.key(deferrable, group_key)
      expect(subject.key).to eq(key)
    end
  end

  describe '#<<' do

    it "adds an id to the event's group" do
      subject << 10
      expect(subject.group).to include(10)
    end

  end

  describe '#realize' do

    let(:ids) {
      [1, 2, 3]
    }
    let(:results) { {
      1 => 2,
      2 => 4,
      3 => 6
    } }

    before do
      deferrable.stub(:call).and_return(results)
      ids.each { |id| subject << id }
    end

    it "calls the event's deferrable with the group" do
      expect(deferrable).to receive(:call).with(subject.group, group_key)
      subject.realize
    end

    it "returns the results" do
      expect(subject.realize).to eq(results)
    end

    context "when a block is given" do
      it "yields a target and value for each id" do
        yielded_ids = []
        # Check that each target has the correct deferrable, group_key and value.
        subject.realize do |target, value|
          expect(target.source).to eq(deferrable)
          expect(target.group_key).to eq(group_key)
          expect(value).to eq(results[target.id])
          yielded_ids << target.id
        end
        # Check that we have all the ids.
        expect(yielded_ids).to match_array(ids)
      end

      context "when a result is missing" do
        before do
          results.delete(1)
        end

        it "yields a nil value for this target" do
          yielded_ids = []
          # Ensure that the missing result is yielded as nil.
          subject.realize do |target, value|
            expect(value).to be_nil if target.id == 1
            yielded_ids << target.id
          end
          # Check that we have all the ids.
          expect(yielded_ids).to match_array(ids)
        end
      end
    end

  end

  describe '#each' do

    let(:ids) {
      [1, 2, 3]
    }

    before do
      ids.each { |id| subject << id }
    end

    it "enumerates all ids in the group" do
      expect(subject.each.to_a).to eq(ids)
    end

  end

  describe '#length' do

    before do
      subject << 1
      subject << 2
    end

    it "is the count of ids in the event's group" do
      expect(subject.length).to eq(2)
    end

  end

  describe '#empty?' do

    context "when the event's group is empty" do
      it "is true" do
        expect(subject).to be_empty
      end
    end

    context "when the event's group has at least one id" do
      before do
        subject << 1
      end

      it "is false" do
        expect(subject).to_not be_empty
      end
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

end
