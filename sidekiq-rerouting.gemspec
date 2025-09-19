# frozen_string_literal: true

require_relative "lib/sidekiq/rerouting/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq-rerouting"
  spec.version = Sidekiq::Rerouting::VERSION
  spec.authors = ["Hazel Bachrach", "Steven Harman"]
  spec.email = ["hibachrach@dropbox.com", "steven@harmanly.com"]

  spec.summary = "A mechanism to reroute queued jobs to a different queue on pickup"
  spec.description = <<~DESC
    A mechanism to reroute queued jobs to a different queue on pickup.
    Can target jobs by job ID or job class.
  DESC
  spec.homepage = "https://github.com/hibachrach/sidekiq-rerouting"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "documentation_uri" => spec.homepage,
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", "~> 7.0"
end
