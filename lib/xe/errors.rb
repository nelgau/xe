module Xe
  # The superclass from which all Xe errors descend.
  class Error < StandardError; end

  # Raised when attempting to enumerate outside of an active context.
  class NoContextError < Error; end
  # Raised when an operation is attempted against an invalid context.
  class InvalidContextError < Error; end
  # Raised when an inconsistent state is detected during context invalidation.
  class InconsistentContextError < Error; end
  # Raised when there are waiting fibers but no values left to realize.
  class DeadlockError < Error; end

  # Raised when a client attempts to defer realization on a disabled context.
  class DeferError < Error; end
  # Raised when attempting to resolve an invalid proxy.
  class InvalidProxyError < Error; end
end
