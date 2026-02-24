# frozen_string_literal: true

require_relative "lib/pidfd/version"

Gem::Specification.new do |spec|
  spec.name = "pidfd"
  spec.version = Pidfd::VERSION
  spec.authors = ["Maciej Mensfeld"]
  spec.email = ["maciej@mensfeld.pl"]

  spec.summary = "Ruby wrapper for Linux pidfd system calls"
  spec.homepage = "https://github.com/mensfeld/pidfd"
  spec.license = "MIT"
  spec.description = <<~DESC
    Provides race-free process management using Linux pidfd (process file descriptors) for safer
    signal delivery and process monitoring
  DESC

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "https://github.com/mensfeld/pidfd"
  spec.metadata["changelog_uri"] = "https://github.com/mensfeld/pidfd/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://github.com/mensfeld/pidfd#readme"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob("{lib}/**/*") + %w[LICENSE CHANGELOG.md README.md pidfd.gemspec]
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", ">= 1.15"
end
