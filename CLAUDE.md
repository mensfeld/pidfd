# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem that provides a wrapper for Linux pidfd (Process File Descriptor) system calls using FFI. The gem enables race-free process management by using kernel-level process file descriptors instead of traditional PIDs.

## Development Commands

### Testing
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/lib/pidfd_spec.rb  # Run specific test file
bundle exec rspec --format documentation  # Verbose test output
```

### Building and Installation  
```bash
rake build                          # Build gem into pkg/ directory
rake install                        # Build and install gem locally
rake install:local                  # Install without network access
rake clean                          # Remove temporary build files
```

### Release Management
```bash
rake release                        # Tag version and push to RubyGems
```

## Code Architecture

### Core Components

- **`lib/pidfd.rb`**: Main class implementing pidfd functionality via FFI syscalls
- **`lib/pidfd/errors.rb`**: Error hierarchy for pidfd operations
- **`lib/pidfd/version.rb`**: Version constant

### Key Implementation Details

The gem uses FFI to make direct syscalls to Linux kernel:
- `pidfd_open` (syscall 434 on x86_64) - creates process file descriptor
- `pidfd_signal` (syscall 424 on x86_64) - sends signals via pidfd
- `waitid` with P_PIDFD - waits for process termination

Thread safety is ensured through mutex synchronization around critical operations.

### Platform Support Detection

The `Pidfd.supported?` method performs runtime checks:
1. Verifies FFI library loading succeeded
2. Excludes macOS/Windows/BSD systems  
3. Attempts creating pidfd for current process to verify kernel support

## Dependencies

- **Runtime**: FFI gem (>= 1.15) for C library bindings
- **Development**: bundler, rake  
- **Testing**: rspec, simplecov, warning gem

## Requirements

- Linux kernel 5.3+ (pidfd support)
- Ruby 3.2+
- x86_64 architecture (syscall numbers are arch-specific)

## Key APIs

- `Pidfd.new(pid)` - Create pidfd for process
- `pidfd.alive?` - Check if process is running (non-blocking)
- `pidfd.signal(signal_name)` - Send signal safely  
- `pidfd.cleanup` - Clean up zombie process
- `Pidfd.supported?` - Runtime platform support check

## Testing Notes

Tests must run on Linux with kernel 5.3+ to verify actual pidfd functionality. On unsupported platforms, tests should verify graceful fallback behavior.