# Pidfd

[![Gem Version](https://badge.fury.io/rb/pidfd.svg)](https://rubygems.org/gems/pidfd)
[![Build Status](https://github.com/mensfeld/pidfd/actions/workflows/ci.yml/badge.svg)](https://github.com/mensfeld/pidfd/actions/workflows/ci.yml)

A Ruby wrapper for Linux pidfd (Process File Descriptor) system calls, providing safer process management with guaranteed process identity.

## What is pidfd?

Process file descriptors (pidfd) were introduced in Linux 5.3 (2019) to solve fundamental problems with traditional PID-based process management:

### The Problem with PIDs

Traditional Unix PIDs have a critical flaw: **PID reuse**. When a process dies, its PID can be immediately reassigned to a new, unrelated process. This creates race conditions where:
- You might send signals to the wrong process
- Process state checks become unreliable
- Security vulnerabilities can arise from PID confusion

### The pidfd Solution

Pidfds provide a **stable reference** to a process that remains valid even if the PID is reused. Key benefits:

- **Race-free signal delivery** - Signals always go to the intended process
- **Reliable process monitoring** - Know definitively when a process exits
- **Thread-safe operations** - No TOCTTOU races
- **Pollable file descriptors** - Integrate with event loops efficiently

## When to Use This Gem

Use pidfd when you need:

- **Reliable process management** in production environments
- **Non-child process monitoring** without being the parent
- **High-security applications** where PID confusion is unacceptable
- **Systems with high process churn** where PID reuse is common
- **Libraries operating in uncontrolled environments**

Don't use pidfd for:
- macOS or Windows (Linux-only feature)
- Kernels older than Linux 5.3
- Simple parent-child relationships (traditional wait works fine)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pidfd'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install pidfd
```

## Requirements

- Linux kernel 5.3 or newer
- Ruby 3.2 or newer
- FFI gem

## Usage

### Basic Process Management

```ruby
require 'pidfd'

# Create a pidfd for a process
process = fork { sleep 10 }
pidfd = Pidfd.new(process)

# Check if process is alive
pidfd.alive? # => true

# Send a signal safely
pidfd.signal('TERM') # => true (signal sent)

# Clean up zombie process after it exits
pidfd.cleanup
```

### Monitoring Non-Child Processes

```ruby
# Monitor any process by PID (requires appropriate permissions)
nginx_pid = File.read('/var/run/nginx.pid').to_i
pidfd = Pidfd.new(nginx_pid)

# Check status without race conditions
if pidfd.alive?
  puts "Nginx is running"
else
  puts "Nginx has stopped"
  pidfd.cleanup
end
```

### Safe Signal Delivery

```ruby
# Traditional approach (UNSAFE - race condition)
Process.kill('TERM', pid) # Might hit wrong process if PID was reused!

# Pidfd approach (SAFE)
pidfd = Pidfd.new(pid)
pidfd.signal('TERM') # Guaranteed to hit the right process or fail safely
```

### Integration with Event Loops

```ruby
# Pidfd provides a pollable file descriptor
pidfd = Pidfd.new(child_pid)

# Use with IO.select for non-blocking monitoring
loop do
  if pidfd.alive?
    # Process still running
    sleep 0.1
  else
    # Process exited
    pidfd.cleanup
    break
  end
end
```

## Platform Support

### Checking Support

```ruby
if Pidfd.supported?
  puts "pidfd is supported on this system"
else
  puts "pidfd is not available (wrong OS or kernel version)"
end
```

### Fallback Strategy

```ruby
def safe_process_check(pid)
  if Pidfd.supported?
    pidfd = Pidfd.new(pid)
    result = pidfd.alive?
    pidfd.cleanup unless result
    result
  else
    # Fallback to traditional (less safe) approach
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end
end
```

## Configuration

### Custom Syscall Numbers

Different architectures may use different syscall numbers. You can configure them:

```ruby
# Default values for x86_64
Pidfd.pidfd_open_syscall = 434
Pidfd.pidfd_signal_syscall = 424

# For other architectures, consult your system headers
```

## Error Handling

```ruby
begin
  pidfd = Pidfd.new(pid)
rescue Pidfd::Errors::PidfdOpenFailedError => e
  # Process doesn't exist or permission denied
  puts "Could not open pidfd: #{e.message}"
end

begin
  pidfd.signal('TERM')
rescue Pidfd::Errors::PidfdSignalFailedError => e
  # Signal delivery failed
  puts "Could not send signal: #{e.message}"
end
```

## Performance Considerations

- **Efficient**: Pidfd operations are kernel-level, very fast
- **Low overhead**: Minimal memory usage per pidfd
- **Scalable**: Handles thousands of processes efficiently
- **Non-blocking**: Supports async operation patterns

## Security

Pidfd provides significant security improvements:
- Prevents signal delivery to wrong processes
- Eliminates PID confusion attacks
- Provides capability-based process references
- Works with Linux security modules (SELinux, AppArmor)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mensfeld/pidfd.

### Running Tests

```bash
bundle exec rspec
```

Tests require a Linux environment with pidfd support.

## Further Reading

- [Linux pidfd documentation](https://man7.org/linux/man-pages/man2/pidfd_open.2.html)
- [LWN: Process-descriptor file descriptors](https://lwn.net/Articles/801319/)
- [Bringing Linux pidfd to Ruby](https://mensfeld.github.io/bringing_linux_pidfd_to_ruby/)

## Author

Based on the pidfd implementation in [Karafka](https://github.com/karafka/karafka) by Maciej Mensfeld.

## Acknowledgments

Special thanks to:
- The Linux kernel team for implementing pidfd
- KJ Tsanaktsidis for Ruby core contributions discussions
- The Karafka community for battle-testing this implementation
