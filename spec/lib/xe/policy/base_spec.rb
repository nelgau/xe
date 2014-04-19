require 'spec_helper'

describe Xe::Policy::Base do

  let(:deferrable) { Xe::Deferrable.new }
  let(:target)     { Xe::Target.new(deferrable, 0) }
  let(:event)      { Xe::Event.from_target(target) }

  describe '#add_event' do
    it "responds" do
      subject.add_event(event)
    end
  end

  describe '#remove_event' do
    it "responds" do
      subject.remove_event(event)
    end
  end

  describe '#update_event' do
    it "responds" do
      subject.update_event(event)
    end
  end

  describe '#wait_event' do
    it "responds" do
      subject.wait_event(event, 0)
    end
  end

  describe '#next_event_key' do
    it "is nil" do
      expect(subject.next_event_key).to be_nil
    end
  end

end
