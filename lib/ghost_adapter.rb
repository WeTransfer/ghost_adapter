require 'ghost_adapter/config'

require 'ghost_adapter/railtie' if defined? ::Rails::Railtie

module GhostAdapter
  def self.config
    @@config
  end

  def self.configure(options = {})
    @@config = GhostAdapter::Config.new(options) # rubocop:disable Style/ClassVars
  end
end
