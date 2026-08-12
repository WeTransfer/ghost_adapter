source 'http://rubygems.org'

gem 'activerecord', '~> 6.0.0'

# concurrent-ruby >= 1.3.5 dropped its transitive `require 'logger'`, which
# breaks ActiveSupport < 7.1 (uninitialized constant
# ActiveSupport::LoggerThreadSafeLevel::Logger). This EOL ActiveRecord never
# received the upstream fix, so pin below that release.
gem 'concurrent-ruby', '< 1.3.5'

gemspec path: '../'
