require 'spec_helper'

describe Xe::Tracer::Event do

  let(:deferrable) { Xe::Deferrable.new }
  let(:target)     { Xe::Target.new(deferrable, 0) }
  let(:event)      { Xe::Event.from_target(target) }

  describe '#initialize' do

    it "sets the events attribute" do
      expect(subject.events).to_not be_nil
    end

  end

  describe '#events' do

    it "is an array" do
      expect(subject.events).to be_an_instance_of(Array)
    end

    it "is initially empty" do
      expect(subject.events).to be_empty
    end

  end

  describe '#clear' do

    context "when there are events in the logger" do
      before do
        subject.call(:event_realize, event)
      end

      it "clears the events" do
        subject.clear
        expect(subject.events).to be_empty
      end

    end

  end

  describe '#call' do

    it "handles 'event_realize' by pushing the event into the array" do
      subject.call(:event_realize, event)
      expect(subject.events).to eq([event])
    end

  end

end
