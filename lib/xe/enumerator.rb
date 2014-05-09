require 'xe/enumerator/impl'
require 'xe/enumerator/worker'
require 'xe/enumerator/proxy'

module Xe
  class Enumerator
    # This is purely to demonstrate that the class implements the Enumerable
    # interface. In reality, every method is overridden and delegated to a
    # new instance of an implementation subclass.
    include Enumerable
    include Impl::Delegators

    attr_reader :enumerable
    attr_reader :options

    # Initializes an instance of a defferable-aware enumerator. You can pass
    # the `:tag` option to differentiate enumerators while debugging.
    def initialize(enumerable, options={})
      @enumerable = enumerable
      @options = options
    end

    def inspect
      contents = enumerable.is_a?(Enumerator) ? "(nested)" : enumerable.inspect
      "#<#{self.class.name} #{contents}>"
    end

    def to_s
      inspect
    end
  end
end
