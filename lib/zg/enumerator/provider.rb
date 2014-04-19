require 'zg/enumerator/provider/base'
require 'zg/enumerator/provider/general'
require 'zg/enumerator/provider/each'
require 'zg/enumerator/provider/map'

module Zg
  class Enumerator

    module Provider
      def self.class_for_method(method)
        case method
        when :each then Provider::Each
        when :map  then Provider::Map
        else            Provider::General
        end
      end
    end

  end
end
