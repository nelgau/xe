require 'xe/enumerator/strategy'
require 'xe/enumerator/delegators'

module Xe
  # This class implements a deferrable-aware Enumerable. It is the engine of
  # concurrency in Xe and permits operations to interleave iteration and
  # realization. Some enumerations operate on each value independently (like
  # each and map) while others necessarily serialize execution via a data-
  # dependent accumulator (like inject) or early termination (like any?). These
  # cases are modeled by two strategies, evaluator and mapper, which
  # respectively use a single- or multi-fiber operation to compute the result.
  #
  # To maximize concurrency (and the potential for large, batch realizations),
  # you should always prefer an enumeration that has no serializing
  # data-dependency. For now, this is limited to each and map. In the future,
  # it would be possible to provide alternatives to, say, inject, when it's
  # known that the operation is associative.
  #
  # This class comes with no ordering guarantee. For most operations, all that
  # can be said is that each successive invocation of the block will arrive
  # in the order of the enumerable. No more can be said in the general case.
  #
  # The enumerator is a simple wrapper for a context-enumerable pair. Each
  # distinct enumeration executes in an instance of Worker::Base.
  class Enumerator
    # Purely to demonstrate that this class implements the Enumerable
    # interface. Every method is overridden and delegated.
    include Enumerable
    include Delegators

    attr_reader :context
    attr_reader :enumerable
    attr_reader :options
    attr_reader :tag

    # Initializes an instance of a defferable-aware enumerator. You can pass
    # the `:tag` option to differentiate enumerators while debugging.
    def initialize(context, enumerable, options={})
      raise NoContextError if context.nil?
      @context = context
      @enumerable = enumerable
      @options = options
      @tag = options[:tag]
    end

    # Returns a new array from the results of running the block once for every
    # element in the enumerable. Substitutes proxies for unrealized values.
    def map(&blk)
      run_mapper(&blk)
    end

    # Similar to map, but returns the original values.
    def each
      run_mapper { |o| yield o; o }
    end

    def inspect
      is_xe_enumerator = enumerable.is_a?(Xe::Enumerator)
      contents = is_xe_enumerator ? "(nested)" : enumerable.inspect
      "#<#{self.class.name} #{contents} (#{tag || '...'})>"
    end

    def to_s
      inspect
    end

    private

    # Runs a computation, returning a value, within a single fiber. If the
    # fiber blocks on a realization, a proxy is returned instead.
    def run_evaluator(&blk)
      Strategy::Evaluator.(context, &blk)
    end

    # Runs an enumeration, returning an array of independent values, within a
    # succession of fibers. If some fiber blocks on a realization, a proxy is
    # substituted for that value.
    def run_mapper(&blk)
      Strategy::Mapper.(context, enumerable, &blk)
    end
  end
end
