require 'xe/version'
require 'xe/errors'
require 'xe/logger'
require 'xe/context'
require 'xe/fiber'
require 'xe/proxy'
require 'xe/realizer'
require 'xe/enumerator'

module Xe
  def self.context(options={}, &b)
    Context.wrap(options, &b)
  end

  def self.realizer(name=nil, &b)
    Realizer.new(name, &b)
  end

  def self.map(e, &b)
    context { |c| c.enum(e).map(&b) }
  end
end
