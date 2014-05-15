module Xe
  class Enumerator
    # This module is a catch-all for enumerations that haven't been implemented
    # in terms of strategies. It simply delegates to the standard method in the
    # enumerable interface, wrapped in a fiber, and returns a proxy if
    # evaluating the enumeration would block.
    module Delegators
      # Returns a single-valued result. If the computation blocks on the
      # realization of a deferred value, a proxy is returned.
      Enumerable.instance_methods.each do |m|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{m}(*args, &blk)
            run_evaluator { enumerable.#{m}(*args, &blk) }
          end
        RUBY
      end
    end
  end
end
