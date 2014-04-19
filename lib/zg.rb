require 'zg/version'
require 'zg/context'
require 'zg/enumerator'
require 'zg/realizer'
require 'fiber'

module Zg
  def self.context(&b)
    Context.wrap(&b)
  end

  def self.each(e, &b)
    context { |c| c.enum(e).each(&b) }
  end

  def self.map(e, &b)
    context { |c| c.enum(e).map(&b) }
  end

  def self.defer(source, id)
    context { |c| c.defer(source, id) }
  end
end
