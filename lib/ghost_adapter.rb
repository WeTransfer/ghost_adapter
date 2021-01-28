require 'ghost_adapter/config'
require 'ghost_adapter/version'

require 'ghost_adapter/railtie' if defined? ::Rails::Railtie

module GhostAdapter
  def self.config
    @@config ||= GhostAdapter::Config.new # rubocop:disable Style/ClassVars
  end

  def self.setup(options = {})
    @@config = GhostAdapter::Config.new(options) # rubocop:disable Style/ClassVars

    yield @@config if block_given?
  end
end
