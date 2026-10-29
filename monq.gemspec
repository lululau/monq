# frozen_string_literal: true

require_relative "lib/monq/version"

Gem::Specification.new do |spec|
  spec.name = "monq"
  spec.version = Monq::VERSION
  spec.authors = ["Liu Xiang"]
  spec.email = ["liuxiang921@gmail.com"]

  spec.summary = "Mongoid + Pry MongoDB query workbench"
  spec.description = "Load user-authored Mongoid models and query MongoDB from a Pry REPL."
  spec.homepage = "https://github.com/lululau/monq"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/lululau/monq"

  # Uncomment the line below to require MFA for gem pushes.
  # This helps protect your gem from supply chain attacks by ensuring
  # no one can publish a new version without multi-factor authentication.
  # See: https://guides.rubygems.org/mfa-requirement-opt-in/
  # spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid", "~> 9.0"
  spec.add_dependency "csv"
  spec.add_dependency "pry", "~> 0.15"
  spec.add_dependency "pry-byebug", "~> 3.10"
  spec.add_dependency "net-ssh-gateway", "~> 2.0"
  spec.add_dependency "terminal-table", "~> 4.0"
  spec.add_dependency "rainbow", "~> 3.1"
  spec.add_dependency "caxlsx", "~> 4.1"
  spec.add_dependency "roo", "~> 2.10"

  # For more information and examples about making a new gem, check out our
  # guide at: https://guides.rubygems.org/make-your-own-gem/
end
