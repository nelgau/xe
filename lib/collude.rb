require 'collude/version'
require 'collude/context'
require 'collude/enumerator'
require 'collude/realizer'

module Collude

  def self.context(&block)
    Context.wrap(&block)
  rescue => e
    puts "E: #{e}"
  end

end
