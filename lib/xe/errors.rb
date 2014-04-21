module Xe
  # The superclass from which all Xe errors descend.
  class Error < StandardError; end
  # Raised when there are waiting fibers but no deferrals to resolve.
  class DeadlockError < Error; end
end
