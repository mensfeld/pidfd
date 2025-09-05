# frozen_string_literal: true

class Pidfd
  # Namespace for all the pidfd errors
  module Errors
    # Base error class for all pidfd errors
    BaseError = Class.new(StandardError)

    # Error raised when pidfd_open syscall fails
    PidfdOpenFailedError = Class.new(BaseError)

    # Error raised when pidfd_signal syscall fails
    PidfdSignalFailedError = Class.new(BaseError)
  end
end
