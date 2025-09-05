# Pidfd Changelog

## 0.6.0 (2025-09-05)
- [Breaking] **BREAKING CHANGE**: Moved main API from `Pidfd::Pidfd` to `Pidfd` class
  - Old: `pidfd = Pidfd::Pidfd.new(pid)` → New: `pidfd = Pidfd.new(pid)`
  - Old: `Pidfd::Pidfd.supported?` → New: `Pidfd.supported?`
  - Old: `Pidfd::Pidfd.pidfd_open_syscall = 434` → New: `Pidfd.pidfd_open_syscall = 434`
  - Error classes remain namespaced as `Pidfd::Errors::*`
  - This simplifies the API and removes redundant nested class structure

## 0.5.0 (2025-09-05)
- [Feature] Initial release extracted from Karafka framework.
- [Feature] Core pidfd functionality for Linux 5.3+.
- [Feature] `Pidfd::Pidfd` class with process management capabilities.
- [Feature] `#alive?` method for race-free process status checking.
- [Feature] `#signal` method for safe signal delivery.
- [Feature] `#cleanup` method for zombie process reaping.
- [Feature] Platform support detection via `Pidfd::Pidfd.supported?`.
- [Feature] Configurable syscall numbers for different architectures.
- [Feature] Thread-safe operations with mutex protection.
- [Feature] Non-blocking process monitoring using IO.select.
- [Feature] Comprehensive error handling with custom exceptions.
- [Feature] Full test suite with RSpec.
- [Feature] GitHub Actions CI/CD pipeline.
- [Feature] Documentation and usage examples.
- [Enhancement] Uses FFI for direct syscall bindings.
- [Enhancement] Supports pidfd_open and pidfd_send_signal syscalls.
- [Enhancement] Implements waitid for process cleanup.
- [Enhancement] Compatible with Ruby 3.2+.
