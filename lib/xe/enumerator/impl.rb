require 'xe/enumerator/impl/delegators'
require 'xe/enumerator/impl/base'
require 'xe/enumerator/impl/general'
require 'xe/enumerator/impl/each'
require 'xe/enumerator/impl/map'

module Xe
  class Enumerator
    module Impl
      # Returns a new enumeration implementation parameterized by method.
      def self.new(method, context, enumerable, options)
        class_for_method(method).new(context, enumerable, options)
      end

      # Returns the implementation class for the given enumerable method.
      def self.class_for_method(method)
        case method
        when :each then Impl::Each
        when :map  then Impl::Map
        else            Impl::General
        end
      end
    end
  end
end
