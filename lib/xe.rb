require 'xe/version'
require 'xe/errors'
require 'xe/configuration'
require 'xe/singletons'
require 'xe/utility'
require 'xe/logger'
require 'xe/proxy'
require 'xe/loom'
require 'xe/models'
require 'xe/context'
require 'xe/policy'
require 'xe/realizer'
require 'xe/enumerator'

module Xe
  extend Singletons

  # Create a new context with the given options (if one doesn't already exist),
  # yield this context to the given block and return the result. If this
  # method is called within an existing context and it will yield that one.
  # You may pass the `:enabled => false` option to the outermost context to
  # disable deferred realization and fiber creation.
  def self.context(options={}, &blk)
    Context.wrap(options, &blk)
  end

  # Constructs a new realizer from a proc. On realization, the block will
  # receive an enumerable of ids and must return a result hash, mapping ids
  # to values (or other deferred objects). You can pass the `tag` argument to
  # help differentiate otherwise anonymous realizers.
  def self.realizer(tag=nil, &realize_proc)
    Realizer.new(tag, &realize_proc)
  end

  # Execute a map operation over a collection using a deferrable-aware mapping
  # enumerator. If no context exists, the operation is wrapped in one.
  def self.map(enumerable, options={}, &blk)
    context(options) do |c|
      c.enum(enumerable, options).map(&blk)
    end
  end

  # Yields a configuration object with which you can control the default
  # behavior of new contexts (e.g., max_fibers).
  def self.configure
    yield(config) if block_given?
  end
end
