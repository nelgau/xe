module Xe
  class Deferrable
    # Returns a map from ids to values. Any id without a value is assumed to be
    # nil. The argument is an arbitrary object conforming to Enumerable.
    def call(group)
      {}
    end

    # Returns a key that will be used to group ids into batches.
    def group_key(id)
      nil
    end

    # Returns a new enumerable collection than responds to :<<. Deferred values
    # will be aggregated into these collections by group key.
    def new_group(key)
      []
    end
  end
end
