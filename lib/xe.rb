require 'xe/version'
require 'xe/errors'
require 'xe/configuration'
require 'xe/singletons'
require 'xe/utility'
require 'xe/tracer'

require 'xe/models'
require 'xe/context'
require 'xe/policy'
require 'xe/proxy'
require 'xe/loom'

require 'xe/realizer'
require 'xe/enumerator'
require 'xe/cache'

module Xe
  extend Singletons

  # Yields a configuration object with which you can control the default
  # behavior of new contexts (e.g., max_fibers).
  def self.configure
    yield(config) if block_given?
  end

  # Create a new context with the given options (if one doesn't already exist),
  # yield this context to the given block and return the result. If this
  # method is called within an existing context and it will yield that one.
  # You may pass the `:enabled => false` option to the outermost context to
  # disable deferred realization and fiber creation.
  def self.context(options={}, &blk)
    Context.wrap(options, &blk)
  end

  # Returns a generic deferrable-aware enumerator for an enumerable. If no
  # context exists, it raises NoContextException. This is syntactic sugar
  # for the Xe.enum method below and is the preferred shorthand.
  def self.[](e, options={})
    raise NoContextError if !Context.exists?
    Context.current.enum(e, options)
  end

  # Constructs a new realizer from a proc. On realization, the block will
  # receive an enumerable of ids and must return a result hash, mapping ids
  # to values (or other deferred objects). You can pass the `tag` argument to
  # help differentiate otherwise anonymous realizers.
  def self.realizer(tag=nil, &realize_proc)
    Realizer.new(tag, &realize_proc)
  end

  # Execute an `each` operation over a collection using a deferring enumerator.
  # If no current context exists, the operation is wrapped.
  def self.each(e, options={}, &blk)
    context(options) { |c| c.enum(e, options).each(&blk) }
  end

  # Execute a `map` operation over a collection using a deferring enumerator.
  # If no current context exists, the operation is wrapped.
  def self.map(e, options={}, &blk)
    context(options) { |c| c.enum(e, options).map(&blk) }
  end

  # Returns a generic deferrable-aware enumerator for an enumerable. If no
  # context exists, it raises NoContextException.
  def self.enum(e, options={})
    raise NoContextError if !Context.exists?
    Context.current.enum(e, options)
  end
end
