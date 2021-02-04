require 'active_record/connection_adapters/mysql2_adapter'
require 'ghost_adapter/migrator'
require 'ghost_adapter/version_checker'

gem 'mysql2', '>= 0.4.4', '< 0.6.0'
require 'mysql2'

module ActiveRecord
  module ConnectionHandling
    # Establishes a connection to the database that's used by all Active Record objects.
    def ghost_mysql2_connection(config)
      config = config.symbolize_keys
      config[:flags] ||= 0

      if config[:flags].is_a? Array
        config[:flags].push 'FOUND_ROWS'.freeze
      else
        config[:flags] |= Mysql2::Client::FOUND_ROWS
      end

      client = Mysql2::Client.new(config)
      if GhostAdapter::Internal.ghost_migration_enabeld?
        dry_run = ENV['DRY_RUN'] == '1'
        GhostAdapter::VersionChecker.validate_executable! unless ENV['SKIP_GHOST_VERSION_CHECK'] == '1'
        ConnectionAdapters::GhostMysql2Adapter.new(client, logger, nil, config, dry_run: dry_run)
      else
        ConnectionAdapters::Mysql2Adapter.new(client, logger, nil, config)
      end
    rescue Mysql2::Error => e
      raise ActiveRecord::NoDatabaseError if e.message.include?('Unknown database')

      raise
    end
  end

  module ConnectionAdapters
    class GhostMysql2Adapter < Mysql2Adapter
      ADAPTER_NAME = 'mysql2_ghost'.freeze

      def initialize(connection, logger, connection_options, config, dry_run: false)
        super(connection, logger, connection_options, config)
        @database = config[:database]
        @dry_run = dry_run
      end

      def execute(sql, name = nil)
        # Only ALTER TABLE statements are automatically skipped by gh-ost
        # We need to manually skip CREATE TABLE, DROP TABLE, and
        # INSERT/DELETE (to schema migrations) for dry runs
        return if dry_run && should_skip_for_dry_run?(sql)

        if (table, query = parse_sql(sql))
          GhostAdapter::Migrator.execute(table, query, database, dry_run)
        else
          super(sql, name)
        end
      end

      private

      attr_reader :database, :dry_run

      ALTER_TABLE_PATTERN = /\AALTER\s+TABLE\W*(?<table_name>\w+)\W*(?<query>.*)$/i.freeze
      QUERY_ALLOWABLE_CHARS = /[^0-9a-z_\s():'"{}]/i.freeze
      CREATE_TABLE_PATTERN = /\Acreate\stable/i.freeze
      DROP_TABLE_PATTERN = /\Acreate\stable/i.freeze
      INSERT_SCHEMA_MIGRATION_PATTERN = /\Ainsert\sinto\s`schema_migrations`/i.freeze
      DROP_SCHEMA_MIGRATION_PATTERN = /\Adelete\sfrom\s`schema_migrations`/i.freeze

      def parse_sql(sql)
        capture = sql.match(ALTER_TABLE_PATTERN)
        return if capture.nil?

        captured_names = capture.names
        return unless captured_names.include? 'table_name'
        return unless captured_names.include? 'query'

        [capture[:table_name], clean_query(capture[:query])]
      end

      def clean_query(query)
        cleaned = query.gsub(QUERY_ALLOWABLE_CHARS, '')
        cleaned.gsub('"', '\"')
      end

      def should_skip_for_dry_run?(sql)
        if create_or_drop_table?(sql)
          puts 'Skipping CREATE TABLE or DROP TABLE for dry run'
          puts 'SQL:'
          puts sql
        end

        create_or_drop_table?(sql) || schema_migration_update?(sql)
      end

      def create_or_drop_table?(sql)
        CREATE_TABLE_PATTERN =~ sql ||
          DROP_TABLE_PATTERN =~ sql
      end

      def schema_migration_update?(sql)
        INSERT_SCHEMA_MIGRATION_PATTERN =~ sql ||
          DROP_SCHEMA_MIGRATION_PATTERN =~ sql
      end
    end
  end
end
