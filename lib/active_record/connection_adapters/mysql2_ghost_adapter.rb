require 'active_record/connection_adapters/mysql2_adapter'
require 'ghost_adapter'
require 'ghost_adapter/migrator'
require 'ghost_adapter/version_checker'
require 'mysql2'

module ActiveRecord
  module ConnectionHandling
    # Establishes a connection to the database that's used by all Active Record objects.
    def mysql2_ghost_connection(config)
      config = config.symbolize_keys
      config[:flags] ||= 0

      if config[:flags].is_a? Array
        config[:flags].push 'FOUND_ROWS'.freeze
      else
        config[:flags] |= Mysql2::Client::FOUND_ROWS
      end

      client = Mysql2::Client.new(config)
      if GhostAdapter::Internal.ghost_migration_enabled?
        dry_run = ENV.fetch('DRY_RUN', nil) == '1'
        GhostAdapter::VersionChecker.validate_executable! unless ENV.fetch('SKIP_GHOST_VERSION_CHECK', nil) == '1'
        ConnectionAdapters::Mysql2GhostAdapter.new(client, logger, nil, config, dry_run: dry_run)
      else
        ConnectionAdapters::Mysql2Adapter.new(client, logger, nil, config)
      end
    rescue Mysql2::Error => e
      raise ActiveRecord::NoDatabaseError if e.message.include?('Unknown database')

      raise
    end
  end

  module ConnectionAdapters
    class Mysql2GhostAdapter < Mysql2Adapter
      ADAPTER_NAME = 'mysql2_ghost'.freeze

      def initialize(connection, logger, connection_options, config, dry_run: false)
        super(connection, logger, connection_options, config)
        @database = config[:database]
        @dry_run = dry_run
      end

      if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.0')
        def execute(sql, name = nil, async: false)
          # Only ALTER TABLE statements are automatically skipped by gh-ost
          # We need to manually skip CREATE TABLE, DROP TABLE, and
          # INSERT/DELETE (to schema migrations) for dry runs
          return if dry_run && should_skip_for_dry_run?(sql)

          if (table, query = parse_sql(sql))
            GhostAdapter::Migrator.execute(table, query, database, dry_run)
          else
            super(sql, name, async: async)
          end
        end
      else
        def execute(sql, name = nil)
          # See comment above -- some tables need to be skipped manually for dry runs
          return if dry_run && should_skip_for_dry_run?(sql)

          if (table, query = parse_sql(sql))
            GhostAdapter::Migrator.execute(table, query, database, dry_run)
          else
            super(sql, name)
          end
        end
      end

      if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('6.1')
        def add_index(table_name, column_name, **options)
          index, algorithm, if_not_exists = add_index_options(table_name, column_name, **options)
          return if if_not_exists && index_exists?(table_name, column_name, name: index.name)

          index_type = index.type&.to_s&.upcase || (index.unique ? 'UNIQUE' : nil)

          sql = build_add_index_sql(
            table_name, quoted_columns(index), index.name,
            index_type: index_type,
            using: index.using,
            algorithm: algorithm
          )

          execute sql
        end

        def remove_index(table_name, column_name = nil, **options)
          return if options[:if_exists] && !index_exists?(table_name, column_name, **options)

          index_name = index_name_for_remove(table_name, column_name, options)
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP INDEX #{quote_column_name(index_name)}"
        end
      else
        def add_index(table_name, column_name, options = {})
          index_name, index_type, index_columns, _index_options = add_index_options(table_name, column_name, **options)

          sql = build_add_index_sql(
            table_name, index_columns, index_name,
            index_type: index_type&.upcase,
            using: options[:using]
          )

          execute sql
        end

        def remove_index(table_name, options = {})
          options = { column: options } unless options.is_a?(Hash)
          index_name = index_name_for_remove(table_name, options)
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP INDEX #{quote_column_name(index_name)}"
        end
      end

      private

      attr_reader :database, :dry_run

      ALTER_TABLE_PATTERN = /\AALTER\s+TABLE\W*(?<table_name>\w+)\W*(?<query>.*)$/i.freeze
      QUERY_ALLOWABLE_CHARS = /[^0-9a-z_\s():'"{},`]/i.freeze
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

      def build_add_index_sql(table_name, column_names, index_name, # rubocop:disable Metrics/ParameterLists
                              index_type: nil, using: nil, algorithm: nil)
        sql = %w[ALTER TABLE]
        sql << quote_table_name(table_name)
        sql << 'ADD'
        sql << index_type
        sql << 'INDEX'
        sql << quote_column_name(index_name)
        sql << "USING #{using}" if using
        sql << "(#{column_names})"
        sql << algorithm

        sql.compact.join(' ').gsub(/\s+/, ' ')
      end

      def quoted_columns(index)
        index.columns.is_a?(String) ? index.columns : quoted_columns_for_index(index.columns, index.column_options)
      end
    end
  end
end
