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
  class << self
    attr_accessor :default_logger
  end

  def self.context(options={}, &b)
    Context.wrap(options, &b)
  end

  def self.realizer(tag=nil, &b)
    Realizer.new(tag, &b)
  end

  def self.map(e, options={}, &b)
    context do |c|
      c.enum(e, options).map(&b)
    end
  end
end
