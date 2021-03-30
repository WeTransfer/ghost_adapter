require 'English'

module GhostAdapter
  class Command
    def initialize(alter:, table:, database: nil, dry_run: false)
      @alter = alter
      @table = table
      @database = GhostAdapter.config.database || database
      @dry_run = dry_run
      validate_args_and_config!
    end

    def to_a
      [
        EXECUTABLE,
        *base_args,
        *config_args,
        *execute_arg
      ]
    end

    private

    EXECUTABLE = 'gh-ost'.freeze

    attr_reader :alter, :database, :table, :dry_run

    def validate_args_and_config!
      raise ArgumentError, 'alter cannot be nil' if alter.nil?
      raise ArgumentError, 'table cannot be nil' if table.nil?
      raise ArgumentError, 'database cannot be nil' if database.nil?
    end

    def base_args
      [
        "--alter=#{alter}",
        "--table=#{table}",
        "--database=#{database}"
      ]
    end

    def config_args
      context = {
        pid: $PID,
        table: table,
        database: database,
        timestamp: Time.now.utc.to_i,
        unique_id: SecureRandom.uuid
      }

      GhostAdapter.config.as_args(context: context)
    end

    def execute_arg
      dry_run ? [] : ['--execute']
    end
  end
end
