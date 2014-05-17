module Xe
  class Enumerator
    # These are implementations of methods in the enumerable interface for
    # which it's possible to give a more efficient solution with fibers. The
    # key idea is that, even if the body of the proc blocks on some
    # realization, we still want to start execution -- it may reveal new
    # deferred values. We gain no benefit from being force to execute the
    # enumeration serially.
    module Implementation
      # Returns a new array from the results of running the block once for each
      # element in the enumerable. If no block is given, an enumerator is
      # returned instead. Substitutes proxies for unrealized values.
      def map(&blk)
        # If no block was given, return the enumerator.
        return self if !blk
        run_mapper { |o| blk.call(o) }
      end

      alias_method :collect, :map

      # Invokes the block once for each element in the enumerable. Returns an
      # array of the elements. If no block is given, an enumerator is returned.
      # Note: When the enumerator's collection is a Hash, this method works
      # slightly differently than the standard #each. In that case, the block
      # will always be invoked with an array representing the pair.
      def each(&blk)
        # If no block was given, return the enumerator.
        return self if !blk
        run_mapper { |o| blk.call(o); o }
      end

      # Combines all elements of the enumerable by applying a binary operation,
      # specified by a block. for each element, the block is passed an
      # accumulator value and the element. The result becomes the new value for
      # the accumulator. Substitutes a proxy for an unrealized return value.
      def inject(*args, &blk)
        # If we have no initial or no block, delegate this to the evaluator.
        return super if !args.any? || !blk
        run_injector(args.first, &blk)
      end

      alias_method :reduce, :inject

      # Passes each element of the collection to the given block. The method
      # returns true if the block never returns false or nil. If the block is
      # not given, it adds an implicit block of {|obj| obj}.
      # Substitutes a proxy for an unrealized return value.
      def all?(&blk)
        blk ||= Proc.new { |o| o }
        run_injector(true) do |acc, o|
          acc && !!blk.call(o)
        end
      end

      # Passes each element of the collection to the given block. The method
      # returns true if the block never returns true. If the block is
      # not given, it adds an implicit block of {|obj| obj}.
      # Substitutes a proxy for an unrealized return value.
      def none?(&blk)
        blk ||= Proc.new { |o| o }
        run_injector(true) do |acc, o|
          acc && !blk.call(o)
        end
      end

      # Passes each element of the collection to the given block. The method
      # returns true if the block ever returns a value other than false or nil.
      # If the block is not given, Ruby adds an implicit block of {|obj| obj}
      # Substitutes a proxy for an unrealized return value.
      def any?(&blk)
        blk ||= Proc.new { |o| o }
        run_injector(false) do |acc, o|
          acc || !!blk.call(o)
        end
      end

      # Passes each element of the collection to the given block. The method
      # returns true if the block returns true exactly once. If the block is
      # not given, one? will return true only if exactly one of the collection
      # members is true.
      def one?(&blk)
        # Slightly tricky. This operation is two fibers deep.
        run_evaluator { count(&blk) == 1 }
      end

      # Returns the number of items in enum, where size is called if it
      # responds to it, otherwise the items are counted through enumeration. If
      # a block is given, counts the number of elements yielding a true value.
      # This implementation doesn't support the argumented form. Substitutes a
      # proxy for an unrealized return value.
      def count(*args, &blk)
        # If we have an argument or no block, delegate this to the evaluator.
        return super if args.any? || !blk
        run_injector(0) do |acc, o|
          blk.call(o) ? acc + 1 : acc
        end
      end

      # Calls the block with two arguments, the item and its index, for each
      # element in the enumerable. Unlike the implementation in the standard
      # library, this method does not support passing arguments to #each.
      def each_with_index(&blk)
        # If we have no block, delegate this to the evaluator and wrap the
        # result in a new enumerator object.
        return wrap(super) if !blk
        run_mapper { |o, i| blk.call(o, i); o }
      end

      # Iterates the given block for each element with an arbitrary object
      # given, and returns the initially given object. If any operation blocked
      # during enumeration, this method may return a proxy.
      def each_with_object(obj, &blk)
        # If we have no block, delegate this to the evaluator.
        return wrap(super) if !blk
        run_injector(obj) do |acc, o|
          blk.call(o, acc)
          acc
        end
      end

      # Returns true if any element of the enumerable equals obj. Equality#
      # uses #==. Substitutes a proxy for an unrealized return value.
      def include?(obj)
        run_injector(false) { |acc, o| acc || (o == obj) }
      end

      alias_method :member?, :include?

      # Returns the object in the enumerable with the maximum value. The block
      # is invoked with a pair (a, b) and should return something analogous to
      # a <=> b. With no block, objects are assumed to implement comparable.
      # Substitutes a proxy for an unrealized return value.
      def max(&blk)
        blk ||= Proc.new { |a, b| a <=> b }
        run_injector(nil) do |acc, o|
          next o if !acc
          blk.call(o, acc) > 0 ? o : acc
        end
      end

      # Returns the object in the enumerable that gives the maximum value from
      # the given block. If no block is given, an enumerator is returned
      # instead. Substitutes a proxy for an unrealized return value.
      def max_by(&blk)
        # If no block was given, return the enumerator.
        return self if !blk
        run_injector(nil) do |acc, o|
          next o if !acc
          # This is not optimal.
          o_val, acc_val = blk.call(acc), blk.call(o)
          (o_val <=> acc_val) > 0 ? o : acc
        end
      end

      # Returns the object in the enumerable with the minimum value. The block
      # is invoked with a pair (a, b) and should return something analogous to
      # a <=> b. With no block, objects are assumed to implement comparable.
      # Substitutes a proxy for an unrealized return value.
      def min(&blk)
        blk ||= Proc.new { |a, b| a <=> b }
        run_injector(nil) do |acc, o|
          next o if !acc
          blk.call(o, acc) > 0 ? o : acc
        end
      end

      # Returns the object in the enumerable that gives the minimum value from
      # the given block. If no block is given, an enumerator is returned
      # instead. Substitutes a proxy for an unrealized return value.
      def min_by(&blk)
        # If no block was given, return the enumerator.
        return self if !blk
        run_injector(nil) do |acc, o|
          next o if !acc
          # This is not optimal.
          o_val, acc_val = blk.call(acc), blk.call(o)
          (o_val <=> acc_val) > 0 ? o : acc
        end
      end

      # Returns an array for all elements of the enumerable for which block is
      # false. If no block is given, an enumerator is returned instead.
      # Substitutes a proxy for an unrealized return value.
      def reject(&blk)
        # If no block was given, return the enumerator.
        return self if !blk
        each_with_object([]) do |o, acc|
          acc << o if !blk.call(o)
        end
      end

      # Returns an array for all elements of the enumerable for which block is
      # true. If no block is given, an enumerator is returned instead.
      # Substitutes a proxy for an unrealized return value.
      def select(&blk)
        # If no block was given, return the enumerator.
        return self if !blk
        each_with_object([]) do |o, acc|
          acc << o if blk.call(o)
        end
      end
    end
  end
end
