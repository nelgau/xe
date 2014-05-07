require 'xe/enumerator/impl/fibers'
require 'xe/enumerator/impl/delegators'
require 'xe/enumerator/impl/base'
require 'xe/enumerator/impl/general'
require 'xe/enumerator/impl/mappable'

module Xe
  class Enumerator
    module Impl
      # Returns a new enumeration implementation parameterized by method.
      def self.new(method, enumerable, options)
        class_for_method(method).new(enumerable, options)
      end

      # Returns the implementation class for the given enumerable method.
      def self.class_for_method(method)
        IMPL_CLASSES[method] || Impl::General
      end

      # This is a map from Enumerable methods to the class that implements
      # them. We need distinct classes so that we may replace the #each method
      # from the perspective of consumers of the Xe::Enumerator class but
      # allow for a trivial implementation otherwise.
      IMPL_CLASSES = {
        :each => Impl::Mappable,
        :map  => Impl::Mappable
      }
    end
  end
end
