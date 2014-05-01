require 'xe/version'
require 'xe/errors'
require 'xe/logger'
require 'xe/models'
require 'xe/utility'
require 'xe/context'
require 'xe/policy'
require 'xe/realizer'
require 'xe/enumerator'

module Xe
  # Create a new context with the given options (if one doesn't already exist),
  # yield this context to the given block and return the result. If this
  # method is called within an existing context and it will yield that one.
  def self.context(options={}, &blk)
    Context.wrap(options, &blk)
  end

  # Constructs a new realizer from a block. On realization, the block will
  # receive an enumerable of ids and must return a result hash mapping ids
  # to values or other deferred objects.
  def self.realizer(tag=nil, &realize_proc)
    Realizer.new(tag, &realize_proc)
  end

  # Execute a map operation over a collection using the Xe map enumerator.
  # If no context already exists, the operation is wrapped in one.
  def self.map(enumerable, options={}, &b)
    context do |c|
      c.enum(enumerable, options).map(&b)
    end
  end
end
