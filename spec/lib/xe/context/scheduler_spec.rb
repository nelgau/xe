require 'spec_helper'

describe Xe::Context::Scheduler do

  subject          { Xe::Context::Scheduler.new(policy) }
  let(:policy)     { Xe::Policy::Base.new }
  let(:deferrable) { Xe::Deferrable.new }

  def new_target(id, group_key)
    Xe::Target.new(deferrable, id, group_key)
  end

  def get_event(target)
    target_key = Xe::Event.target_key(target)
    subject.events[target_key]
  end

  describe '#initialize' do

    it "sets the policy attribute" do
      expect(subject.policy).to eq(policy)
    end

    it "sets the events attribute" do
      expect(subject.events).to_not be_nil
    end

  end

  describe '#events' do

    it "is a hash" do
      expect(subject.events).to be_an_instance_of(Hash)
    end

    it "is initially empty" do
      expect(subject.events).to be_empty
    end

  end

  describe '#add_target' do
    let(:target1) { new_target(0, 0) }

    context "when the target has no associated event in the queue" do

      it "fills the queue" do
        subject.add_target(target1)
        expect(subject).to_not be_empty
      end

      it "creates an event for associated target key" do
        subject.add_target(target1)
        expect(get_event(target1)).to be_an_instance_of(Xe::Event)
      end

      it "create an event with the target's deferrable" do
        subject.add_target(target1)
        expect(get_event(target1).deferrable).to eq(deferrable)
      end

      it "creates an event with the target's id" do
        subject.add_target(target1)
        expect(get_event(target1).group).to include(target1.id)
      end

      it "creates an event with the target's group_key" do
        subject.add_target(target1)
        expect(get_event(target1).group_key).to eq(target1.group_key)
      end

      it "notifies the policy that a new event has been created" do
        captured_event = nil
        expect(policy).to receive(:add_event) do |event|
          captured_event = event
        end
        subject.add_target(target1)
        expect(captured_event).to_not be_nil
        expect(captured_event).to eq(get_event(target1))
      end

    end

    context "when the target has an associated event in the queue" do
      let(:target2) { new_target(1, 0) }

      before do
        subject.add_target(target1)
      end

      it "maps both targets to the same event" do
        subject.add_target(target2)
        expect(get_event(target1)).to eq(get_event(target2))
      end

      it "extends the existing event's group" do
        subject.add_target(target2)
        expect(get_event(target1).group).to include(target2.id)
      end

      it "notifies the policy that an event has been updated" do
        captured_event = nil
        expect(policy).to receive(:update_event) do |event|
          captured_event = event
        end
        subject.add_target(target2)
        expect(captured_event).to_not be_nil
        expect(captured_event).to eq(get_event(target2))
      end

    end

  end

  describe '#wait_event' do
    let(:target) { new_target(0, 0) }

    context "when the target has no associated event in the queue" do
      it "is a no-op" do
        subject.wait_target(target, 1)
      end
    end

    context "when the target has an associated event in the queue" do
      before do
        subject.add_target(target)
      end

      it "notifies the policy that a fiber is waiting on an event" do
        captured_event = nil
        captured_depth = 0
        expect(policy).to receive(:wait_event) do |event, depth|
          captured_event = event
          captured_depth = depth
        end

        subject.wait_target(target, 1)

        expect(captured_event).to_not be_nil
        expect(captured_event).to eq(get_event(target))
        expect(captured_depth).to eq(1)
      end
    end

  end

  describe '#next_event' do

    context "when the queue is empty" do
      it "is nil" do
        expect(subject.next_event).to be_nil
      end
    end

    context "when the queue contains events" do
      let(:target1) { new_target(0, 0) }
      let(:target2) { new_target(1, 1) }

      before do
        subject.add_target(target1)
        subject.add_target(target2)
      end

      it "removes the event" do
        subject.next_event
        expect(subject.events.length).to eq(1)
      end

      it "notifies the policy that the event has been removed" do
        captured_event = nil
        expect(policy).to receive(:remove_event) do |event|
          captured_event = event
        end
        event = subject.next_event
        expect(captured_event).to_not be_nil
        expect(captured_event).to eq(event)
      end

      context "when the policy punts on the decision" do
        it "returns an event" do
          expect(subject.next_event).to be_an_instance_of(Xe::Event)
        end

        it "returns the first event" do
          event = get_event(target1)
          expect(subject.next_event).to eq(event)
        end
      end

      context "when the policy specifies a particular key" do
        let(:policy_key) do
          get_event(target2).key
        end

        before do
          policy.stub(:next_event_key) { policy_key }
        end

        it "returns an event" do
          expect(subject.next_event).to be_an_instance_of(Xe::Event)
        end

        it "returns the event for the given key" do
          expect(subject.next_event.key).to eq(policy_key)
        end
      end

    end

  end

  describe '#pop_event' do
    let(:target) { new_target(0, 0) }

    context "when the queue is empty" do
      it "is nil" do
        expect(subject.pop_event(target)).to be_nil
      end
    end

    context "when the queue contains an event" do
      before do
        subject.add_target(target)
      end

      it "returns the associated event" do
        event = get_event(target)
        expect(subject.pop_event(target)).to eq(event)
      end

      it "removes the associated event" do
        subject.pop_event(target)
        expect(subject).to be_empty
      end

      it "notifies the policy that the event has been removed" do
        captured_event = nil
        expect(policy).to receive(:remove_event) do |event|
          captured_event = event
        end
        event = subject.pop_event(target)
        expect(captured_event).to_not be_nil
        expect(captured_event).to eq(event)
      end

    end

  end

  describe '#empty?' do

    context "when the queue is empty" do
      it "is true" do
        expect(subject).to be_empty
      end
    end

    context "when the queue has pending events" do
      let(:target) { new_target(0, 0) }

      before do
        subject.add_target(target)
      end

      it "is false" do
        expect(subject).to_not be_empty
      end
    end

  end

end
