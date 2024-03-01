# frozen_string_literal: true

require_relative "lib/spongebob/version"

Gem::Specification.new do |spec|
  spec.name = "spongebob"
  spec.version = Spongebob::VERSION
  spec.authors = ["Demetra Opinioni.net Srl"]
  spec.email = ["developers@opinioni.net"]

  spec.summary = "The Spongebob gem provides real-time interaction with Nifi using Kafka topics."
  spec.description = <<~DESC
    The Spongebob gem provides a set of features for real-time interaction with Nifi by utilizing Kafka topics.
    It allows you to easily integrate your Ruby applications with Nifi and leverage the power of Kafka for seamless data processing and streaming.

    Features:
    - Publish and consume messages from Kafka topics in real-time.
    - Handle message serialization and deserialization.
    - Error handling and retry mechanisms.
    - Seamless integration with Nifi's data flow management.
  DESC

  spec.homepage = "https://github.com/demetra-it/spongebob"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.metadata["bugs_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "configatron", ">= 4.0"
  spec.add_runtime_dependency "oj", ">= 3.11"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
