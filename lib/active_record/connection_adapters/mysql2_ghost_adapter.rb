require 'active_record/connection_adapters/mysql2_adapter'
require 'ghost_adapter'
require 'ghost_adapter/migrator'
require 'ghost_adapter/version_checker'
require 'mysql2'

module ActiveRecord
  module ConnectionAdapters
    register(
      'mysql2_ghost',
      'ActiveRecord::ConnectionAdapters::Mysql2GhostAdapter',
      'active_record/connection_adapters/mysql2_ghost_adapter'
    )

    class Mysql2GhostAdapter < Mysql2Adapter
      ADAPTER_NAME = 'mysql2_ghost'.freeze

      def initialize(config)
        super
        @database = @config[:database]
        @dry_run = ENV.fetch('DRY_RUN', nil) == '1'
      end

      def execute(sql, name = nil, allow_retry: false)
        execute_with_ghost(sql) { super(sql, name, allow_retry: allow_retry) }
      end

      def exec_insert(sql, name = nil, binds = [], pk = nil, sequence_name = nil, returning: nil) # rubocop:disable Metrics/ParameterLists, Naming/MethodParameterName
        return if skip_schema_migration_write?(sql)

        super
      end

      def exec_delete(sql, name = nil, binds = [])
        return 0 if skip_schema_migration_write?(sql)

        super
      end

      def add_index(table_name, column_name, **options)
        return super unless GhostAdapter::Internal.ghost_migration_enabled?

        index, algorithm, if_not_exists = add_index_options(table_name, column_name, **options)
        return if if_not_exists && index_exists?(table_name, column_name, name: index.name)

        execute build_add_index_sql(table_name, index, algorithm)
      end

      def remove_index(table_name, column_name = nil, **options)
        return super unless GhostAdapter::Internal.ghost_migration_enabled?
        return if options[:if_exists] && !index_exists?(table_name, column_name, **options)

        index_name = index_name_for_remove(table_name, column_name, options)
        execute "ALTER TABLE #{quote_table_name(table_name)} DROP INDEX #{quote_column_name(index_name)}"
      end

      ALTER_TABLE_PATTERN = /\AALTER\s+TABLE\W*(?<table_name>\w+)\W*(?<query>.*)$/i
      QUERY_ALLOWABLE_CHARS = /[^0-9a-z_\s():'"{},`]/i
      CREATE_TABLE_PATTERN = /\Acreate\stable/i
      DROP_TABLE_PATTERN = /\Adrop\stable/i

      private

      def validate_ghost_version!
        return if @ghost_version_validated
        return if ENV.fetch('SKIP_GHOST_VERSION_CHECK', nil) == '1'

        GhostAdapter::VersionChecker.validate_executable!
        @ghost_version_validated = true
      end

      def execute_with_ghost(sql)
        return yield unless GhostAdapter::Internal.ghost_migration_enabled?
        return if dry_run && should_skip_for_dry_run?(sql)

        if (table, query = parse_sql(sql))
          validate_ghost_version!
          GhostAdapter::Migrator.execute(table, query, database, dry_run)
        else
          yield
        end
      end

      attr_reader :database, :dry_run

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
        return false unless create_or_drop_table?(sql)

        puts 'Skipping CREATE TABLE or DROP TABLE for dry run'
        puts 'SQL:'
        puts sql
        true
      end

      def skip_schema_migration_write?(sql)
        GhostAdapter::Internal.ghost_migration_enabled? && dry_run && schema_migration_update?(sql)
      end

      def create_or_drop_table?(sql)
        CREATE_TABLE_PATTERN =~ sql ||
          DROP_TABLE_PATTERN =~ sql
      end

      def schema_migration_update?(sql)
        quoted_table = Regexp.escape(quoted_schema_migrations_table_name)

        sql.match?(/\Ainsert\sinto\s#{quoted_table}/i) ||
          sql.match?(/\Adelete\sfrom\s#{quoted_table}/i)
      end

      def quoted_schema_migrations_table_name
        quote_table_name(
          "#{ActiveRecord::Base.table_name_prefix}#{ActiveRecord::Base.schema_migrations_table_name}#{ActiveRecord::Base.table_name_suffix}"
        )
      end

      def build_add_index_sql(table_name, index, algorithm)
        sql = [
          'ALTER TABLE', quote_table_name(table_name), 'ADD', schema_creation.accept(index), algorithm
        ]

        sql.compact.join(' ')
      end
    end
  end
end
