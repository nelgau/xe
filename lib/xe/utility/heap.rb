module Xe
  class Heap
    include Enumerable

    # Represents an item in the heap.
    Node = Struct.new(:key, :value)

    attr_reader :compare
    attr_reader :indexes
    attr_reader :nodes

    def initialize(&compare)
      @compare = compare || default_compare
      @indexes = {}
      @nodes = []
    end

    # Calls blk once for each item in the heap, passing that element as a
    # parameter. If no block is given, an enumerator is returned instead. The
    # first item is guaranteed to compare highest relative to the comparator
    # but all other items are returned in no particular order.
    def each(&blk)
      to_enum.each(&blk)
    end

    # Returns the number of items in the heap.
    def length
      @nodes.length.to_i
    end

    # Returns true if there are no items in the heap.
    def empty?
      @nodes.empty?
    end

    # Returns the value for a given key, or nil.
    def [](key)
      index = @indexes[key]
      return unless index
      @nodes[index].value
    end

    # Returns true if there is an item in the heap with the given key.
    def has_key?(key)
      !!@indexes[key]
    end

    # Assigns a vlaue for the given key, or replaces an existing one.
    def []=(key, value)
      push(key, value)
    end

    # Assigns a vlaue for the given key, or replaces an existing one.
    def push(key, value)
      index = @indexes[key]
      if index
        @nodes[index].value = value
        sift(index)
      else
        add(key, value)
      end
    end

    # Removes the item for a given key and returns the key and value as a pair.
    # If there is no item with the given key, it returns nil.
    def delete(key)
      index = @indexes[key]
      return unless index
      remove(index).to_a
    end

    # Re-sort the item with the given key.
    def update(key)
      index = @indexes[key]
      sift(index) if index
    end

    # Returns the item that compares highest relative to the comparator as a
    # pair, or nil if the heap is empty. The heap is not mutated.
    def peek
      return if @nodes.empty?
      @nodes[0].to_a
    end

    # Removes and returns the item that compares highest relative to the
    # comparator as a pair, or nil if the heap is empty. The heap is mutated.
    def pop
      return if @nodes.empty?
      remove(0).to_a
    end

    # Removes and returns all items as pairs in sorted order relative to the
    # comparator. The heap is mutated and empty after this operation.
    def pop_all
      result = []
      until @nodes.empty?
        result << remove(0).to_a
      end
      result
    end

    private

    def default_compare
      Proc.new { |o1, o2| o1 <=> o2 }
    end

    def to_enum
      ::Enumerator.new do |y|
        @nodes.each { |n| y << n.to_a }
      end
    end

    def add(key, value)
      index = @nodes.length
      @nodes << Node.new(key, value)
      @indexes[key] = index
      sift_up(index)
    end

    def remove(index)
      li = @nodes.length - 1
      swap_indexes(index, li)
      node = @nodes.pop
      @indexes.delete(node.key)
      sift(index) if index < li
      node
    end

    def sift(index)
      sift_up(index)
      sift_down(index)
    end

    def sift_up(index)
      ci = index
      while ci > 0
        pi = (ci - 1) / 2
        co, po = @nodes[ci].value, @nodes[pi].value
        break if @compare.call(po, co) > 0
        swap_indexes(pi, ci)
        ci = pi
      end
    end

    def sift_down(index)
      pi = index
      length = @nodes.length
      loop do
        ci = pi * 2 + 1
        break unless ci < length
        po = @nodes[pi].value
        co = @nodes[ci].value
        ci_right = ci + 1
        if ci_right < length
          co_right = @nodes[ci_right].value
          if @compare.call(co_right, co) > 0
            ci, co = ci_right, co_right
          end
        end
        break if @compare.call(po, co) > 0
        swap_indexes(pi, ci)
        pi = ci
      end
    end

    def swap_indexes(i1, i2)
      n1, n2 = @nodes[i1], @nodes[i2]
      k1, k2 = n1.key, n2.key
      @nodes[i1], @nodes[i2] = n2, n1
      @indexes[k1], @indexes[k2] = @indexes[k2], @indexes[k1]
    end
  end
end
