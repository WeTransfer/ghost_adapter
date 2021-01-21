require_relative 'lib/ghost_adapter/version'

Gem::Specification.new do |spec|
  spec.name          = "ghost_adapter"
  spec.version       = GhostAdapter::VERSION
  spec.authors       = ["Austin C Roos"]
  spec.email         = ["acroos@hey.com"]

  spec.summary       = %q{Run your ActiveRecord ALTER TABLE migrations through gh-ost}
  spec.description   = %q{Run your ActiveRecord ALTER TABLE migrations through gh-ost}
  spec.homepage      = "https://github.com/acroos/ghost_adapter"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")


  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ghost_adapter"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>= 5'

  spec.add_development_dependency 'bump', '~> 0'
  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'minitest', '~> 5.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1'
end
