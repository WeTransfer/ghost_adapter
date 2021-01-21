require 'open3'

module GhostAdapter
  class GhostError < StandardError; end

  class GhostInstallationError < GhostError
    def initialize(installed_version, min_version)
      super("Installed gh-ost version (#{installed_version}) incompatible; Please install #{min_version}")
    end
  end

  class GhostConfigurationError < GhostError
    def initialize(missing_keys)
      super("Missing configuration keys: (#{missing_keys.join(', ')})")
    end
  end

  class GhostExecutionError < GhostError
    def initialize(message)
      super(message)
    end
  end

  class GhostExecutor
    ALTER_TABLE_REGEX = /\AALTER\s+TABLE\W*(?<table_name>\w+)\W*(?<query>.*)$/i

    attr_reader :dry_run

    def initialize(dry_run:)
      @dry_run = dry_run
    end

    def execute(sql, name = nil)
      # Only ALTER TABLE statements are automatically skipped for us by gh-ost
      # We need to manually skip CREATE TABLE, DROP TABLE, and INSERT/DELETE (to schema migrations)
      return if dry_run && should_skip_for_dry_run?(sql)
      table, query = parse_sql(sql)

      if table.nil? || query.nil?
        return ActiveRecord::Base.connection.original_execute(sql, name)
      end

      run_ghost(table, query)
    end

    def parse_sql(sql)
      capture = sql.match(ALTER_TABLE_REGEX)
      return if capture.nil?
      captured_names = capture.names
      return unless captured_names.include? 'table_name'
      return unless captured_names.include? 'query'

      [ capture[:table_name], clean_query(capture[:query]) ]
    end

    def clean_query(query)
      # Clean the SQL query to remove everything that isn't an expect
      # character within a migration.
      cleaned = query.gsub(/[^0-9a-z_\s\(\)\:\'\"\`\{\}]/i, '')

      # Escape the double quotes which made it through (usually for column
      # defaults). Should the migration include an already escaped double
      # quote, it will be stripped above and re-escaped here. This
      # prevents the overzealous escaping of escapes.
      cleaned.gsub!('"', '\"')

      # Remove unnecessary backticks
      cleaned.gsub('`', '')
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
      sql.start_with?('CREATE TABLE') ||
        sql.start_with?('DROP TABLE')
    end

    def schema_migration_update?(sql)
      sql.include?('INSERT INTO `schema_migrations`') ||
        sql.include?('DELETE FROM `schema_migrations`')
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
        "--database=#{database_name}",
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
      puts 'Cooling down for 10 seconds...'
      10.times do
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

    def database_name
      if Rails.env.development?
        db_config = Rails.application.config.database_configuration['development']
        db_config['database']
      else
        'live'
      end
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
