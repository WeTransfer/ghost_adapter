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
    @@ghost_migration_enabled = false # rubocop:disable Style/ClassVars

    def self.load_task
      return if @loaded

      load File.join(File.dirname(__FILE__), 'tasks', 'ghost_adapter.rake')

      @loaded = true
    end

    def self.enable_ghost_migration!
      @@ghost_migration_enabled = true # rubocop:disable Style/ClassVars
    end

    def self.ghost_migration_enabeld?
      env_val = ENV['GHOST_MIGRATE']&.downcase
      return false if %w[0 n no f false].include?(env_val)

      !!@@ghost_migration_enabled || %w[1 y yes t true].include?(env_val)
    end
  end
end
