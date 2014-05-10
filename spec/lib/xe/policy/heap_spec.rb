require 'spec_helper'

describe Xe::Policy::Heap do

  subject        { Xe::Policy::Heap.new(&priority) }
  let(:priority) { nil }

  let(:deferrable) { Xe::Deferrable.new }

  def new_event(group_key)
    Xe::Event.new(deferrable, group_key)
  end

  describe '.default_priority' do

    subject { Xe::Policy::Heap.default_priority }

    it "is callable" do
      expect(subject.respond_to?(:call)).to be_true
    end

    describe '#call' do

      let(:event1_depth)  { 0 }
      let(:event1_length) { 0 }

      let(:event2_depth)  { 0 }
      let(:event2_length) { 0 }

      let(:event1) { stub_event(event1_length) }
      let(:event2) { stub_event(event2_length) }

      let(:data1) { Xe::Policy::Heap::EventData.new(event1, event1_depth) }
      let(:data2) { Xe::Policy::Heap::EventData.new(event2, event2_depth) }

      def invoke_call
        subject.call(data1, data2)
      end

      def stub_event(length)
        double(Xe::Event).tap do |event|
          event.stub(:length).and_return(length)
        end
      end

      context "when the first is shallower than the second" do
        let(:event1_depth) { 1 }
        let(:event2_depth) { 2 }

        it "is 1" do
          puts "#{data1} #{data2}"
          expect(invoke_call).to eq(1)
        end
      end

      context "when the first is deeper than the second" do
        let(:event1_depth) { 2 }
        let(:event2_depth) { 1 }

        it "is -1" do
          expect(invoke_call).to eq(-1)
        end
      end

      context "when both are at the same depth" do
        let(:event1_depth) { 1 }
        let(:event2_depth) { 1 }

        context "when the first is smaller than the second" do
          let(:event1_length) { 1 }
          let(:event2_length) { 2 }

          it "is 1" do
            expect(invoke_call).to eq(1)
          end
        end

        context "when the first is larger than the second" do
          let(:event1_length) { 2 }
          let(:event2_length) { 1 }

          it "is -1" do
            expect(invoke_call).to eq(-1)
          end
        end

        context "when both are the same size" do
          let(:event1_length) { 1 }
          let(:event2_length) { 1 }

          it "is 0" do
            expect(invoke_call).to eq(0)
          end
        end
      end

    end

  end

  describe Xe::Policy::Heap::EventData do

    subject     { Xe::Policy::Heap::EventData.new(event, depth) }
    let(:event) { new_event(0) }
    let(:depth) { nil }

    describe '#initialize' do

      it "sets the event" do
        expect(subject.event).to eq(event)
      end

      it "sets the min depth to a positive integer" do
        expect(subject.min_depth).to be > 0
      end

    end

    describe '#apply_depth' do

      let(:depth) { 10 }

      it "decreases min_depth for depths lower than the stored value" do
        subject.apply_depth(9)
        expect(subject.min_depth).to eq(9)
      end

      it "doesn't update min_depth for depths greater than the stored value" do
        subject.apply_depth(11)
        expect(subject.min_depth).to eq(10)
      end

    end

    describe '#length' do

      before do
        5.times { |i| event << i }
      end

      it "is the count of ids in the event" do
        expect(subject.length).to eq(5)
      end

    end

  end

  describe '#initialize' do

    context "when priority is unspecified" do
      let(:priority) { nil }
      it "sets the priority attribute with the default" do
        expect(subject.priority).to eq(subject.class.default_priority)
      end
    end

    context "when the priority is specified" do
      let(:priority) { Proc.new { |ed1, ed2| 0 } }
      it "sets the priority attribute" do
        expect(subject.priority).to eq(priority)
      end
    end

    it "sets the queue attribute" do
      expect(subject.queue).to_not be_nil
    end

    it "sets the updated_keys attribute" do
      expect(subject.updated_keys).to_not be_nil
    end

  end

  describe '#priority' do
    let(:event_data) do
      double(Xe::Policy::Heap::EventData).tap do |event_data|
        event_data.stub(:min_depth).and_return(0)
        event_data.stub(:length).and_return(0)
      end
    end

    it "responds to call with an instance of Fixnum" do
      result = subject.priority.call(event_data, event_data)
      expect(result).to be_an_instance_of(Fixnum)
    end
  end

  describe '#queue' do

    it "is an instance of Xe::Heap" do
      expect(subject.queue).to be_an_instance_of(Xe::Heap)
    end

    it "was constructed to use #priority as the comparator" do
      expect(subject.queue.compare).to eq(subject.priority)
    end

    it "is initially empty" do
      expect(subject.queue).to be_empty
    end

  end

  describe '#updated_keys' do

    it "is a set" do
      expect(subject.updated_keys).to be_an_instance_of(Set)
    end

    it "is initially empty" do
      expect(subject.updated_keys).to be_empty
    end

  end

  describe '#add_event' do

    let(:event) { new_event(0) }

    it "adds a new event data model to the queue" do
      subject.add_event(event)
      expect(subject.queue.length).to eq(1)
    end

    it "adds a new event data model with the correct key" do
      subject.add_event(event)
      expect(subject.queue.has_key?(event.key)).to be_true
    end

    it "adds a new event data model with the correct event" do
      subject.add_event(event)
      expect(subject.queue[event.key].event).to eq(event)
    end

  end

  describe '#remove_event' do

    let(:event) { new_event(0) }

    context "when the event isn't in the queue" do
      it "is a no-op" do
        subject.remove_event(event)
      end
    end

    context "when the event is in the queue" do
      before do
        subject.add_event(event)
      end

      it "removes the event (key)" do
        subject.remove_event(event)
        expect(subject.queue.has_key?(event.key)).to be_false
      end

      it "removes the event (length)" do
        subject.remove_event(event)
        expect(subject.queue.length).to eq(0)
      end

      context "if the event was previously queue for re-heapification" do
        before do
          subject.update_event(event)
        end

        it "removes the event's key from the set of delayed updates" do
          subject.remove_event(event)
          expect(subject.updated_keys.member?(event.key)).to be_false
        end
      end
    end

  end

  describe '#update_event' do

    let(:event) { new_event(0) }

    context "when the event isn't already in the queue" do
      it "doesn't add the event's key to the set of delayed updates" do
        subject.update_event(event)
        expect(subject.updated_keys.member?(event.key)).to be_false
      end
    end

    context "when the event is in the queue" do
      before do
        subject.add_event(event)
      end

      it "adds the event's key to the set of delayed updates" do
        subject.update_event(event)
        expect(subject.updated_keys.member?(event.key)).to be_true
      end
    end

  end

  describe '#update_event' do

    let(:event) { new_event(0) }

    context "when the event isn't already in the queue" do
      it "is an no-op" do
        subject.wait_event(event, 1)
      end
    end

    context "when the event is in the queue" do
      before do
        subject.add_event(event)
      end

      it "updates the event metadata's min_depth" do
        subject.wait_event(event, 1)
        expect(subject.queue[event.key].min_depth).to eq(1)
      end

      it "adds the event's key to the set of delayed updates" do
        subject.wait_event(event, 1)
        expect(subject.updated_keys.member?(event.key)).to be_true
      end
    end

  end

  describe '#next_event_key' do

    context "when the queue is empty" do
      it "is nil" do
        expect(subject.next_event_key).to be_nil
      end
    end

    context "when two events are in the queue" do
      let(:event1) do
        new_event(0).tap do |event|
          event << 1
          event << 2
        end
      end

      let(:event2) do
        new_event(1).tap do |event|
          event << 3
        end
      end

      before do
        subject.add_event(event1)
        subject.add_event(event2)
      end

      it "is the key of the highest priority event" do
        expect(subject.next_event_key).to eq(event2.key)
      end

      it "removes the event from the queue" do
        key = subject.next_event_key
        expect(subject.queue.has_key?(key)).to be_false
      end

      context "when an event is updated" do
        before do
          # The first should now have higher priority.
          event2 << 4
          event2 << 5
          # Schedule the update on the next flush.
          subject.update_event(event2)
        end

        it "flushes all updates" do
          subject.next_event_key
          expect(subject.updated_keys).to be_empty
        end

        it "is the key of the highest priority event (after update)" do
          expect(subject.next_event_key).to eq(event1.key)
        end
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
