require 'xe/enumerator/impl/base'
require 'xe/enumerator/impl/general'
require 'xe/enumerator/impl/each'
require 'xe/enumerator/impl/map'

module Xe
  class Enumerator
    module Impl
      def self.new(method, context, enum, options)
        class_for_method(method).new(context, enum, options)
      end

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
