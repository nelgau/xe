module Xe
  class Proxy < BasicObject
    def initialize(context, &value_block)
      @__context = context
      @__value_block = value_block
      @__has_value = false
    end

    def __get_value
      return if @__has_value
      @__value = @__value_block.call(@__context)
      @__has_value = true
    end

    def __has_value?
      @__has_value
    end

    protected

    def method_missing(method, *args, &block)
      __get_value
      @__value.__send__(method, *args, &block)
    end
  end
end
