module Xe
  # The superclass from which all Xe errors descend.
  class Error < StandardError; end

  # Raised when an attempt is made to enumerate outside of an active context.
  class NoContextError < Error; end
  # Raised when a client attempts to defer realization on a disabled context.
  class DeferError < Error; end
  # Raised when there are waiting fibers but no deferrals to resolve.
  class DeadlockError < Error; end
end
