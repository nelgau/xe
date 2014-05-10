module Xe::Test
  # This exception is thrown and caught by the specs. It would be unwise to
  # rescue from a very general exception like StandardError as this would
  # hide obvious flaws in the code.
  class Error < StandardError; end
end
