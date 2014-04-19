require 'spec_helper'
require 'set'

describe Xe::Heap do
  include Xe::Test::Mock::Heap

  subject       { Xe::Heap.new(&compare) }
  let(:compare) { Proc.new { |o1, o2| o1 <=> o2 } }

  # Verify the heap property.
  def is_heap?(heap)
    compare = heap.compare
    nodes = heap.nodes
    length = nodes.length
    max_parent = (length - 2) / 2
    (0..max_parent).each do |pi|
      po       = nodes[pi]
      co_left  = nodes[pi * 2 + 1]
      co_right = nodes[pi * 2 + 2]
      expect(compare.call(po, co_left )).to_not eq(1)
      expect(compare.call(po, co_right)).to_not eq(1)
    end
  end

  # Verify that the relationship between the heap nodes and the key-index map
  # is consistent across mutating operation.
  def is_consistent?(heap)
    heap.each do |key, value|
      expect(heap[key]).to eq(value)
    end
  end

  shared_examples_for "a correct heap" do
    it "constructs a correct heap" do
      expect(is_heap?(subject)).to be_true
    end
  end

  shared_examples_for "a consistent heap" do
    it "constructs a correct heap" do
      expect(is_consistent?(subject)).to be_true
    end
  end

  describe '#each' do

    it "returns an enumerator" do
      expect(subject.each).to be_an_instance_of(Enumerator)
    end

    it "enumerates all values in the heap" do
      subject.push('a', 2)
      subject.push('b', 1)
      expect(subject.each.to_a).to eq([['a', 2], ['b', 1]])
    end

  end

  describe '#length' do

    it "is an integer" do
      expect(subject.length).to be_an_instance_of(Fixnum)
    end

    it "is the count of items in the heap" do
      subject.push('a', 1)
      subject.push('b', 2)
      expect(subject.length).to eq(2)
    end

  end

  describe '#empty?' do

    context "when the heap is empty" do
      it "is true" do
        expect(subject).to be_empty
      end
    end

    context "when the heap has at least one item" do
      before { subject.push('a', 1) }

      it "is false" do
        expect(subject).to_not be_empty
      end
    end

  end

  describe '#[]' do

    context "when the key isn't present" do
      it "returns nil" do
        expect(subject['a']).to be_nil
      end
    end

    context "when the key is present" do
      before do
        subject.push('a', 2)
        subject.push('b', 1)
      end

      it "returns the associated object" do
        expect(subject['a']).to eq(2)
      end
    end

  end

  describe '#has_key?' do

    context "when the key isn't present" do
      it "is false" do
        expect(subject.has_key?('a')).to be_false
      end
    end

    context "when the key is present" do
      before do
        subject.push('a', 2)
        subject.push('b', 1)
      end

      it "is true" do
        expect(subject.has_key?('a')).to be_true
      end
    end

  end

  describe '#[]=' do

    it "sets a value for a key" do
      subject['a'] = 2
      subject['b'] = 1
      expect(subject['a']).to eq(2)
    end

  end

  describe '#push' do

    context "when adding new items (var. 1)" do
      let(:push_items) { [
        ['d', 3],
        ['e', 4],
        ['a', 1],
        ['b', 2],
        ['c', 5]
      ] }

      before do
        push_items.each do |key, value|
          subject.push(key, value)
        end
      end

      it_behaves_like "a correct heap"
      it_behaves_like "a consistent heap"

      it "inserts the correct value for each key" do
        push_items.each do |key, value|
          expect(subject[key]).to eq(value)
        end
      end
    end

    context "when adding new items (var. 2)" do
      let(:push_items) { [
        ['z', 2],
        ['w', 4],
        ['x', 3],
        ['u', 3],
        ['y', 3]
      ] }

      before do
        push_items.each do |key, value|
          subject.push(key, value)
        end
      end

      it_behaves_like "a correct heap"
      it_behaves_like "a consistent heap"

      it "inserts the correct value for each key" do
        push_items.each do |key, value|
          expect(subject[key]).to eq(value)
        end
      end
    end

    context "when 1000 random items are inserted" do
      it "has the expected end state (#{XE_STRESS_LEVEL} run(s))" do
        XE_STRESS_LEVEL.times do
          heap = Xe::Heap.new(&compare)

          pushed_items = {}
          1000.times do |key|
            value = Random.rand(10000)
            heap.push(key, value)
            pushed_items[key] = value
          end

          expect(is_heap?(heap)).to be_true
          expect(is_consistent?(heap)).to be_true

          pushed_items.each do |key, value|
            expect(heap[key]).to eq(value)
          end
        end
      end
    end

    context "when replacing items (var. 1)" do
      let(:push_items) { [
        ['d', 3],
        ['c', 4],
        ['e', 8],
        ['a', 1],
        ['b', 2]
      ] }

      before do
        push_items.each do |key, value|
          subject.push(key, value)
        end
        # Key 'c' is replaced.
        subject.push('c', 5)
      end

      it_behaves_like "a correct heap"
      it_behaves_like "a consistent heap"

      it "replaces the value for each key" do
        expect(subject['c']).to eq(5)
      end
    end

    context "when replacing items (var. 2)" do
      let(:push_items) { [
        ['d', 6],
        ['b', 2],
        ['c', 3],
        ['a', 2],
        ['e', 1]
      ] }

      before do
        push_items.each do |key, value|
          subject.push(key, value)
        end
        # Keys 'a' and 'd' are replaced.
        subject.push('d', 8)
        subject.push('a', 10)
      end

      it_behaves_like "a correct heap"
      it_behaves_like "a consistent heap"

      it "replaces the value for each key" do
        expect(subject['a']).to eq(10)
        expect(subject['d']).to eq(8)
      end
    end

    context "when 1000 items are inserted and 500 randomly replaced" do
      it "has the expected end state (#{XE_STRESS_LEVEL} runs)" do
        XE_STRESS_LEVEL.times do |i|
          heap = Xe::Heap.new(&compare)

          1000.times do |key|
            value = Random.rand(10000)
            heap.push(key, value)
          end

          replaced_items = {}
          500.times do
            key   = Random.rand(1000)
            value = Random.rand(10000)
            heap.push(key, value)
            replaced_items[key] = value
          end

          expect(is_heap?(heap)).to be_true
          expect(is_consistent?(heap)).to be_true

          replaced_items.each do |key, value|
            expect(heap[key]).to eq(value)
          end
        end
      end
    end

  end

  describe '#delete' do

    context "when the key isn't present" do
      it "is a no-op" do
        subject.delete('a')
      end

      it "returns nil" do
        expect(subject.delete('a')).to be_nil
      end
    end

    context "when the key is present" do
      let(:push_items) { [
        ['f', 5],
        ['q', 3],
        ['r', 2],
        ['k', 9],
        ['p', 8]
      ] }

      before do
        push_items.each do |key, value|
          subject.push(key, value)
        end
      end

      it "returns the value for the given key" do
        expect(subject.delete('f')).to eq(5)
      end

      it "removes the item with the given key" do
        subject.delete('f')
        expect(subject['f']).to be_nil
      end

      it "reduces the length of the heap by one" do
        subject.delete('p')
        expect(subject.length).to eq(push_items.length - 1)
      end

      context "after deleting" do
        before do
          subject.delete('r')
        end

        it_behaves_like "a correct heap"
        it_behaves_like "a consistent heap"
      end
    end

    context "when 1000 items are inserted and 500 randomly deleted" do
      it "has the expected end state (#{XE_STRESS_LEVEL} runs)" do
        XE_STRESS_LEVEL.times do |i|
          heap = Xe::Heap.new(&compare)

          1000.times do |key|
            value = Random.rand(10000)
            heap.push(key, value)
          end

          deleted_items = Set.new
          500.times do
            key   = Random.rand(1000)
            heap.delete(key)
            deleted_items << key
          end

          expect(is_heap?(heap)).to be_true
          expect(is_consistent?(heap)).to be_true

          deleted_items.each do |key|
            expect(heap[key]).to be_nil
            expect(heap.has_key?(key)).to be_false
          end
        end
      end
    end

  end

  describe '#update' do

    let(:push_items) { [
      ['b', 3],
      ['a', 4],
      ['d', 5],
      ['e', 4],
      ['c', 1]
    ] }

    before do
      push_items.each do |key, internal|
        subject.push(key, new_value_mock(internal))
      end
    end

    context "when values are updated (towards the root)" do
      before do
        # The key 'a' should now be the root.
        subject['a'].internal = 10
      end

      it "sifts" do
        before_index = subject.indexes['a']
        subject.update('a')
        after_index = subject.indexes['a']
        expect(before_index).to_not eq(after_index)
      end

      it "preserves the heap" do
        subject.update('a')
        expect(subject.peek[0]).to eq('a')
        expect(subject.peek[1].internal).to eq(10)
      end

      context "after updating" do
        before { subject.update('a') }

        it_behaves_like "a correct heap"
        it_behaves_like "a consistent heap"
      end
    end

    context "when values are updated (towards the leaves)" do
      before do
        # The key 'e' should now be at a leaf.
        subject['e'].internal = 0
      end

      it "sifts" do
        before_index = subject.indexes['e']
        subject.update('e')
        after_index = subject.indexes['e']
        expect(before_index).to_not eq(after_index)
      end

      it "preserves consistency" do
        expect(subject['e'].internal).to eq(0)
      end

      context "after updating" do
        before { subject.update('e') }

        it_behaves_like "a correct heap"
        it_behaves_like "a consistent heap"
      end
    end

  end

  describe '#peek' do

    context "when the heap is empty" do
      it "is nil" do
        expect(subject.peek).to be_nil
      end
    end

    context "when the heap has items" do
      before do
        subject.push('b', 1)
        subject.push('a', 2)
      end

      it "is the root item" do
        expect(subject.peek).to eq(['a', 2])
      end

      it "is the same value return by #pop" do
        key, object = subject.peek
        expect(subject.pop).to eq([key, object])
      end
    end

  end

  describe '#pop' do

    context "when the heap is empty" do
      it "is nil" do
        expect(subject.pop).to be_nil
      end
    end

    context "when the heap contains items" do
      let(:push_items) { [
        ['e', 2],
        ['a', 8],
        ['d', 3],
        ['b', 1],
        ['c', 9]
      ] }

      before do
        push_items.each do |key, object|
          subject.push(key, object)
        end
      end

      it "returns the root key and object" do
        key, object = subject.pop
        expect(key).to eq('c')
        expect(object).to eq(9)
      end

      it "reduces the length of the heap by one" do
        subject.pop
        expect(subject.length).to eq(push_items.length - 1)
      end

      context "when popping iteratively" do
        it "returns the items in sorted order" do
          popped_items = []
          while (pair = subject.pop)
            popped_items << pair
          end

          sorted_items = push_items.sort_by { |(k, o)| -o }
          expect(popped_items).to eq(sorted_items)
        end
      end
    end

  end

  describe '#pop_all' do

    it "is an array" do
      expect(subject.pop_all).to be_an_instance_of(Array)
    end

    context "when the heap is empty" do
      it "is empty" do
        expect(subject.pop_all).to be_empty
      end
    end

    context "when the heap contains items" do
      let(:push_items) { [
        ['z', 3],
        ['y', 1],
        ['u', 5],
        ['x', 2],
        ['w', 4]
      ] }

      before do
        push_items.each do |key, object|
          subject.push(key, object)
        end
      end

      it "exhausts the heap" do
        subject.pop_all
        expect(subject).to be_empty
      end

      it "returns the items in sorted order" do
        sorted_items = push_items.sort_by { |(k, o)| -o }
        expect(subject.pop_all).to eq(sorted_items)
      end
    end

  end

end
