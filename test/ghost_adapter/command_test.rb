require 'test_helper'
require 'ghost_adapter/command'

module GhostAdapter
  class CommandTest < MiniTest::Test
    def test_starts_with_ghost_executable
      GhostAdapter.stub :config, config_with_db do
        command = GhostAdapter::Command.new(alter: '', table: '')
        assert_equal command.to_a[0], 'gh-ost'
      end
    end

    def test_alter_arg
      alter = 'ADD COLUMN foos'
      GhostAdapter.stub :config, config_with_db do
        command = GhostAdapter::Command.new(alter: alter, table: '')
        assert_includes command.to_a, "--alter=#{alter}"
      end
    end

    def test_table_arg
      table = 'foos'
      GhostAdapter.stub :config, config_with_db do
        command = GhostAdapter::Command.new(alter: '', table: table)
        assert_includes command.to_a, "--table=#{table}"
      end
    end

    def test_database_arg
      db_name = 'testdbname'
      GhostAdapter.stub :config, config_with_db(db_name) do
        command = GhostAdapter::Command.new(alter: '', table: '')
        assert_includes command.to_a, "--database=#{db_name}"
      end
    end

    def test_with_config_args
      config = GhostAdapter::Config.new(verbose: true, database: 'db', max_load: 1200)
      GhostAdapter.stub :config, config do
        command = GhostAdapter::Command.new(alter: '', table: '')
        assert_includes command.to_a, '--verbose'
        assert_includes command.to_a, '--max-load=1200'
      end
    end

    def test_with_execute
      GhostAdapter.stub :config, config_with_db do
        command = GhostAdapter::Command.new(alter: '', table: '', dry_run: false)
        assert_includes command.to_a, '--execute'
      end
    end

    def test_dry_run
      GhostAdapter.stub :config, config_with_db do
        command = GhostAdapter::Command.new(alter: '', table: '', dry_run: true)
        refute_includes command.to_a, '--execute'
      end
    end

    private

    def config_with_db(name = 'db')
      GhostAdapter::Config.new(database: name)
    end
  end
end
