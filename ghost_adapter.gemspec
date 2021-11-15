require_relative 'lib/ghost_adapter/version'

Gem::Specification.new do |spec|
  spec.name          = 'ghost_adapter'
  spec.version       = GhostAdapter::VERSION
  spec.authors       = ['Austin C Roos']
  spec.email         = ['austin.roos@wetransfer.com']

  spec.summary       = 'Run ActiveRecord migrations through gh-ost'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/wetransfer/ghost_adapter'
  spec.license       = 'Hippocratic'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|doc|bin)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 5', '< 6.2'
  spec.add_dependency 'mysql2', '>= 0.4.0', '< 0.6.0'

  spec.add_development_dependency 'bump', '~> 0'
  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop', '~> 1'
end
