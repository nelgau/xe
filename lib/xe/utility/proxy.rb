module Xe
  class Proxy < BasicObject
    attr_reader :__subject

    def self.proxy?(object)
      object.__xe_proxy? rescue false
    end

    def self.resolve(proxy_or_object)
      proxy?(proxy_or_object) ?
        proxy_or_object.__resolve_subject :
        proxy_or_object
    end

    def initialize(&subject_block)
      @__subject_block = subject_block
      @__has_subject = false
    end

    def ==(other)
      __resolve_subject == other
    end

    def method_missing(method, *args, &blk)
      __resolve_subject.__send__(method, *args, &blk)
    end

    def __xe_proxy?
      true
    end

    def __subject?
      @__has_subject
    end

    def __set_subject(subject)
      @__subject = subject
      @__has_subject = true
      # Allow the garbage collector to reclaim the block's captured scope.
      @__subject_block = nil
    end

    def __resolve_subject
      __set_subject(@__subject_block.call) unless __subject?
      @__subject
    end
  end
end
