require 'active_record'
require 'active_support/all'

require 'active_record/connection_adapters/mysql2_ghost_adapter'

require 'ghost_adapter/config'

require 'ghost_adapter/railtie' if defined? Rails::Railtie

module GhostAdapter
  def self.config
    @@config ||= GhostAdapter::Config.new # rubocop:disable Style/ClassVars
  end

  def self.setup(options = {})
    new_config = GhostAdapter::Config.new(options)

    if defined? @@config
      @@config.merge!(new_config)
    else
      @@config = new_config # rubocop:disable Style/ClassVars
    end

    yield @@config if block_given?
  end

  def self.clear_config
    @@config = GhostAdapter::Config.new # rubocop:disable Style/ClassVars
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

    def self.ghost_migration_enabled?
      env_val = ENV.fetch('GHOST_MIGRATE', nil)&.downcase
      return false if %w[0 n no f false].include?(env_val)

      !!@@ghost_migration_enabled || %w[1 y yes t true].include?(env_val)
    end
  end
end
