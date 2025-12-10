# frozen_string_literal: true

class Pidfd
  # Namespace for all the pidfd errors
  # @api public
  module Errors
    # Base error class for all pidfd errors
    # @api public
    BaseError = Class.new(StandardError)

    # Error raised when pidfd_open syscall fails
    # @api public
    PidfdOpenFailedError = Class.new(BaseError)

    # Error raised when pidfd_signal syscall fails
    # @api public
    PidfdSignalFailedError = Class.new(BaseError)
  end
end
