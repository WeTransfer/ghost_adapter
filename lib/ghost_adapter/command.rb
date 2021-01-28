module GhostAdapter
  class Command
    class << self
      def build(alter:, table:, dry_run: false)
        config = GhostAdapter.config
        validate_args_and_config!(alter, table, config)

        command +
          base_args(alter, table, config.database) +
          config.as_args +
          execute_arg(dry_run)
      end

      private

      def validate_args_and_config!(alter, table, config)
        raise ArgumentError, 'alter cannot be nil' if alter.nil?
        raise ArgumentError, 'table cannot be nil' if table.nil?
        raise ArgumentError, 'database name missing in config' if config.database.nil?
      end

      def command
        ['gh-ost']
      end

      def base_args(alter, table, database)
        [
          "--alter=#{alter}",
          "--table=#{table}",
          "--database=#{database}"
        ]
      end

      def execute_arg(dry_run)
        dry_run ? [] : ['--execute']
      end
    end
  end
end
