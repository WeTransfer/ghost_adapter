module GhostAdapter
  class Command
    def initialize(alter:, table:, dry_run: false)
      @alter = alter
      @table = table
      @dry_run = dry_run
      validate_args_and_config!
    end

    def to_a
      [
        EXECUTABLE,
        *base_args,
        *GhostAdapter.config.as_args,
        *execute_arg
      ]
    end

    private

    EXECUTABLE = 'gh-ost'.freeze

    attr_reader :alter, :table, :database, :dry_run

    def validate_args_and_config!
      raise ArgumentError, 'alter cannot be nil' if alter.nil?
      raise ArgumentError, 'table cannot be nil' if table.nil?
      raise ArgumentError, 'database name missing in config' if GhostAdapter.config.database.nil?
    end

    def base_args
      [
        "--alter=#{alter}",
        "--table=#{table}",
        "--database=#{GhostAdapter.config.database}"
      ]
    end

    def execute_arg
      dry_run ? [] : ['--execute']
    end
  end
end
