module Xe
  class Deferrable
    # Returns a map from ids to values. Any id without a realized value is
    # assumed to be nil. The first argument may be an arbitrary object instance
    # conforming to Enumerable.
    def call(ids)
      {}
    end

    # Returns a key that will be used to group ids into batches.
    def group_key(id)
      nil
    end

    # Returns a new enumerable than responds to :<<.
    def new_group(key)
      []
    end
  end
end
