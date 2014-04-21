require 'xe/version'
require 'xe/errors'
require 'xe/context'
require 'xe/enumerator'
require 'xe/realizer'

module Xe
  def self.context(&b)
    Context.wrap(&b)
  end

  def self.map(e, &b)
    context { |c| c.enum(e).map(&b) }
  end
end
