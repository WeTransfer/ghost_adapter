require 'ghost_adapter/command'

module GhostAdapter
  class MigrationError < StandardError
    def initialize(exit_code)
      super("gh-ost migration failed. exit code: #{exit_code}")
    end
  end

  class Migrator
    def initialize(table, query, dry_run)
      @table = table
      @query = query
      @dry_run = dry_run
    end

    def start
      run_process
      cooldown if dry_run
    end

    private

    attr_reader :table, :query, :dry_run

    MIGRATION_STATE_PATTERN = /\sState:\s(?<state>[^;]*)/i.freeze

    def run_process
      command = GhostAdapter::Command.build(alter: query, table: table, dry_run: dry_run)
      Open3.popen2e(*command) do |_stdin, stdout_stderr, wait_thread|
        stdout_stderr.each_line do |line|
          cutover_if_ready(line)
          puts "[gh-ost]:\t\t#{line}"
        end

        raise MigrationError, wait_thread.value.exitstatus unless wait_thread.value.success?
      end
      # A little buffer time in case of consecutive alter table commands
      sleep 5
    end

    def build_ghost_command
      replica_server_id = rand(100_000)

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
        "--panic-flag-file=/tmp/ghost.panic.#{migration_id}.flag",
        "--assume-master-host=#{main_db_host}",
        "--postpone-cut-over-flag-file=#{cutover_flag_file}",
        "--serve-socket-file=/tmp/ghost.#{migration_id}.sock",
        "--replica-server-id=#{replica_server_id}"
      ]

      command << "--password=#{migration_db_password}" unless migration_db_password.blank?

      command << '--allow-on-master' if Rails.env.development?

      unless dry_run
        command << '--initially-drop-ghost-table'
        command << '--initially-drop-old-table'
        command << '--ok-to-drop-table'
        command << '--execute'
      end

      command
    end

    def cutover_if_ready(output_line)
      state = migration_state(output_line)
      return unless state&.downcase == 'postponing cut-over'

      return unless File.exist? cutover_flag_file

      File.delete(cutover_flag_file)
    end

    def migration_state(output_line)
      match = MIGRATION_STATE_PATTERN.match(output_line)
      return '' if match.nil?

      match.named_captures['state'] || ''
    end

    def migration_id
      @migration_id ||= "#{table}_#{SecureRandom.hex}"
    end

    def cutover_flag_file
      @cutover_flag_file ||= "/tmp/ghost.postpone.#{migration_id(table)}.flag"
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
