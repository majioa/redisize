require_relative 'lib/redisize/version'

Gem::Specification.new do |spec|
  spec.name          = "redisize"
  spec.version       = Redisize::VERSION
  spec.authors       = ["Pavel «Malo» Skrylev"]
  spec.email         = ["majioa@yandex.ru"]

  spec.summary       = %q{Make json record cacheable to redis}
  spec.description   = %q{Make json record cacheable to redis via various adapters like Resque, Sidekiq, etc}
  spec.homepage      = "https://github.com/majioa/redisize"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/majioa/redisize"
  spec.metadata["changelog_uri"] = "https://github.com/majioa/redisize/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_development_dependency('pry')
end
