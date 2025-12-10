# frozen_string_literal: true

require 'ffi'

# Main class that wraps Linux pidfd functionality for Ruby
# @api public
class Pidfd
  extend FFI::Library

  begin
    ffi_lib FFI::Library::LIBC

    # direct usage of this is only available since glibc 2.36, hence we use bindings and call
    # it directly via syscalls
    attach_function :fdpid_open, :syscall, %i[long int uint], :int
    attach_function :fdpid_signal, :syscall, %i[long int int pointer uint], :int
    attach_function :waitid, %i[int int pointer uint], :int

    API_SUPPORTED = true
  # LoadError is a parent to FFI::NotFoundError
  rescue LoadError
    API_SUPPORTED = false
  ensure
    private_constant :API_SUPPORTED
  end

  # https://github.com/torvalds/linux/blob/7e90b5c295/include/uapi/linux/wait.h#L20
  P_PIDFD = 3

  # Wait for child processes that have exited
  WEXITED = 4

  # Default syscall numbers for x86_64 Linux
  # These can be overridden if needed for different architectures
  # Pidfd open call number
  # @api public
  DEFAULT_PIDFD_OPEN_SYSCALL = 434

  # Pidfd signal call number
  # @api public
  DEFAULT_PIDFD_SIGNAL_SYSCALL = 424

  private_constant :P_PIDFD, :WEXITED

  class << self
    # @return [Integer] syscall number for pidfd_open
    # @api public
    attr_accessor :pidfd_open_syscall

    # @return [Integer] syscall number for pidfd_signal
    # @api public
    attr_accessor :pidfd_signal_syscall

    # @return [Boolean] true if syscall is supported via FFI
    # @api public
    def supported?
      # If we were not even able to load the FFI C lib, it won't be supported
      return false unless API_SUPPORTED
      # Won't work on macOS because it does not support pidfd
      return false if RUBY_DESCRIPTION.include?('darwin')
      # Won't work on Windows for the same reason as on macOS
      return false if RUBY_DESCRIPTION.match?(/mswin|ming|cygwin/)

      # There are some OSes like BSD that will have C lib for FFI bindings but will not support
      # the needed syscalls. In such cases, we can just try and fail, which will indicate it
      # won't work. The same applies to using new glibc on an old kernel.
      new(::Process.pid)

      true
    rescue Errors::PidfdOpenFailedError
      false
    end
  end

  # Set default syscall numbers
  self.pidfd_open_syscall = DEFAULT_PIDFD_OPEN_SYSCALL
  self.pidfd_signal_syscall = DEFAULT_PIDFD_SIGNAL_SYSCALL

  # @param pid [Integer] pid of the node we want to work with
  # @api public
  def initialize(pid)
    @mutex = Mutex.new

    @pid = pid
    @pidfd = open_pidfd(pid)
    @pidfd_io = IO.new(@pidfd)
  end

  # @return [Boolean] true if given process is alive, false if no longer
  # @api public
  def alive?
    @pidfd_select ||= [@pidfd_io]

    if @mutex.owned?
      return false if @cleaned

      IO.select(@pidfd_select, nil, nil, 0).nil?
    else
      @mutex.synchronize do
        return false if @cleaned

        IO.select(@pidfd_select, nil, nil, 0).nil?
      end
    end
  end

  # Cleans the zombie process
  # @note This should run **only** on processes that exited, otherwise will wait
  # @api public
  def cleanup
    @mutex.synchronize do
      return if @cleaned

      waitid(P_PIDFD, @pidfd, nil, WEXITED)

      @pidfd_io.close
      @pidfd_select = nil
      @pidfd_io = nil
      @pidfd = nil
      @cleaned = true
    end
  end

  # Sends given signal to the process using its pidfd
  # @param sig_name [String] signal name
  # @return [Boolean] true if signal was sent, otherwise false or error raised. `false`
  #   returned when we attempt to send a signal to a dead process
  # @note It will not send signals to dead processes
  # @api public
  def signal(sig_name)
    @mutex.synchronize do
      return false if @cleaned
      # Never signal processes that are dead
      return false unless alive?

      result = fdpid_signal(
        self.class.pidfd_signal_syscall,
        @pidfd,
        Signal.list.fetch(sig_name),
        nil,
        0
      )

      return true if result.zero?

      raise Errors::PidfdSignalFailedError, result
    end
  end

  private

  # Opens a pidfd for the provided pid
  # @param pid [Integer]
  # @return [Integer] pidfd
  def open_pidfd(pid)
    pidfd = fdpid_open(
      self.class.pidfd_open_syscall,
      pid,
      0
    )

    return pidfd if pidfd != -1

    raise Errors::PidfdOpenFailedError, pidfd
  end
end

require_relative 'pidfd/version'
require_relative 'pidfd/errors'
