require 'active_record/connection_adapters/mysql2_adapter'

gem "mysql2", ">= 0.4.4", "< 0.6.0"
require "mysql2"

module ActiveRecord
  module ConnectionHandling
    # Establishes a connection to the database that's used by all Active Record objects.
    def ghost_mysql2_connection(config)
      config = config.symbolize_keys
      config[:flags] ||= 0

      if config[:flags].kind_of? Array
        config[:flags].push "FOUND_ROWS".freeze
      else
        config[:flags] |= Mysql2::Client::FOUND_ROWS
      end

      client = Mysql2::Client.new(config)
      if ENV['GHOST_MIGRATION'] == '1'
        dry_run = ENV['DRY_RUN'] == '1'
        ConnectionAdapters::GhostMysql2Adapter.new(client, logger, nil, config, dry_run: dry_run)
      else
        ConnectionAdapters::Mysql2Adapter.new(client, logger, nil, config)
      end
    rescue Mysql2::Error => error
      if error.message.include?("Unknown database")
        raise ActiveRecord::NoDatabaseError
      else
        raise
      end
    end
  end

  module ConnectionAdapters
    class GhostMysql2Adapter < Mysql2Adapter
      ADAPTER_NAME = 'ghost_mysql2'.freeze

      def initialize(connection, logger, connection_options, config, dry_run: false)
        super(connection, logger, connection_options, config)
        @dry_run = dry_run
      end

      def execute(sql, name = nil)
        # Only ALTER TABLE statements are automatically skipped by gh-ost
        # We need to manually skip CREATE TABLE, DROP TABLE, and 
        # INSERT/DELETE (to schema migrations) for dry runs
        return if dry_run && should_skip_for_dry_run?(sql)

        if (table, query = parse_sql(sql))
          run_ghost(table, query)
        else
          super(sql, name)
        end
      end

      private

      attr_reader :dry_run
  
      ALTER_TABLE_REGEX = /\AALTER\s+TABLE\W*(?<table_name>\w+)\W*(?<query>.*)$/i
  
      def parse_sql(sql)
        capture = sql.match(ALTER_TABLE_REGEX)
        return if capture.nil?
        captured_names = capture.names
        return unless captured_names.include? 'table_name'
        return unless captured_names.include? 'query'
  
        [ capture[:table_name], clean_query(capture[:query]) ]
      end
  
      def clean_query(query)
        cleaned = query.gsub(/[^0-9a-z_\s\(\)\:\'\"\{\}]/i, '')
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
        /\Acreate\stable/i =~ sql ||
          /\Adrop\stable/i =~ sql
      end
  
      def schema_migration_update?(sql)
        /\Ainsert\sinto\s`schema_migrations`/i =~ sql ||
          /\Adelete\sfrom\s`schema_migrations`/i =~ sql
      end
  
      def build_ghost_command(table, query)
        replica_server_id = rand(100000)
  
        command = [
          'gh-ost',
          '--max-load=Threads_running=150',
          '--critical-load=Threads_running=4000',
          '--chunk-size=1000',
          "--throttle-control-replicas=#{read_replica_db_url}",
          '--max-lag-millis=3000',
          "--user=#{migration_db_user}",
          "--host=#{read_replica_db_url}",
          "--database=#{db_name}",
          "--table=#{table}",
          '--dml-batch-size=1000',
          '--verbose',
          "--alter=#{query}",
          '--assume-rbr',
          '--cut-over=default',
          '--exact-rowcount',
          '--concurrent-rowcount',
          '--default-retries=1200',
          '--cut-over-lock-timeout-seconds=9',
          "--panic-flag-file=/tmp/ghost.panic.#{migration_id(table)}.flag",
          "--assume-master-host=#{main_db_host}",
          "--postpone-cut-over-flag-file=#{cutover_flag_file(table)}",
          "--serve-socket-file=/tmp/ghost.#{migration_id(table)}.sock",
          "--replica-server-id=#{replica_server_id}",
        ]
  
        unless migration_db_password.blank?
          command << "--password=#{migration_db_password}"
        end
  
        if Rails.env.development?
          command << '--allow-on-master'
        end
  
        unless dry_run
          command << '--initially-drop-ghost-table'
          command << '--initially-drop-old-table'
          command << '--ok-to-drop-table'
          command << '--execute'
        end
  
        command
      end
  
      def run_ghost(table, query)
        ghost_command = build_ghost_command(table, query)
  
        Open3.popen2e(*ghost_command) do |_stdin, stdout_stderr, wait_thread|
          stdout_stderr.each_line do |line|
            if ready_to_cutover?(line)
              cutover_file = cutover_flag_file(table)
              puts "Removing cutover file (#{cutover_file}) to continue migration"
              File.delete(cutover_file) if File.exists? cutover_file
            end
            puts "[gh-ost]:\t#{line}"
          end
  
          unless wait_thread.value.success?
            raise GhostExecutionError.new("gh-ost migration failed. exit code: #{wait_thread.value.exitstatus}")
          end
        end
  
        cooldown
      end
  
      def cooldown
        return if dry_run
        puts 'Cooling down for 5 seconds...'
        5.times do
          sleep 1
          print '.'
        end
        puts ''
      end
  
      def ready_to_cutover?(output_line)
        match = /\sState:\s(?<state>[^;]*)/.match(output_line)
        return false if match.nil?
  
        state = match[:state] rescue nil
        return false if state.nil?
  
        state.downcase == 'postponing cut-over'
      end
  
      def migration_id(table)
        @migration_id ||= "#{table}_#{SecureRandom.hex}"
      end
  
      def cutover_flag_file(table)
        "/tmp/ghost.postpone.#{migration_id(table)}.flag"
      end
  
      def db_name
        ENV['DATABASE_NAME']
      end
  
      def main_db_host
        ENV['DATABASE_MAIN_HOST']
      end
  
      def read_replica_db_url
        ENV['DATABASE_READ_REPLICA_HOST']
      end
  
      def migration_db_user
        ENV['DATABASE_MIGRATION_USER']
      end
  
      def migration_db_password
        ENV['DATABASE_MIGRATION_PASSWORD']
      end
    end
  end
end
