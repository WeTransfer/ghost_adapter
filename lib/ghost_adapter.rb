require 'ghost_adapter/config'

require 'ghost_adapter/railtie' if defined? ::Rails::Railtie

module GhostAdapter
  def self.config
    @@config ||= GhostAdapter::Config.new # rubocop:disable Style/ClassVars
  end

  def self.setup(options = {})
    @@config = GhostAdapter::Config.new(options) # rubocop:disable Style/ClassVars

    yield @@config if block_given?
  end

  module Internal
    def self.load_task
      return if @loaded

      load File.join(File.dirname(__FILE__), 'tasks', 'ghost_adapter.rake')

      @loaded = true
    end

    def self.ready_to_migrate!
      @@ready_to_migrate = true # rubocop:disable Style/ClassVars
    end

    def self.ready_to_migrate?
      env_val = ENV['GHOST_MIGRATE']&.downcase
      return false if %w[0 n no f false].include?(env_val)

      !!@@ready_to_migrate || %w[1 y yes t true].include?(env_val)
    end
  end
end
