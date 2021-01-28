require 'ghost_adapter/command'

module GhostAdapter
  class MigrationError < StandardError
    def initialize(exit_code)
      super("gh-ost migration failed. exit code: #{exit_code}")
    end
  end

  class Migrator
    def self.execute(table, query, dry_run)
      command = GhostAdapter::Command.new(alter: query, table: table, dry_run: dry_run)
      Open3.popen2e(*command.to_a) do |_stdin, stdout_stderr, wait_thread|
        stdout_stderr.each_line do |line|
          puts "[gh-ost]:\t\t#{line}"
        end

        raise MigrationError, wait_thread.value.exitstatus unless wait_thread.value.success?
      end
      # A little buffer time in case of consecutive alter table commands
      sleep 5
    end
  end
end
