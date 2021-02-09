require 'test_helper'
require 'ghost_adapter/command'

module GhostAdapter
  class CommandTest < MiniTest::Test
    def setup
      GhostAdapter.clear_config
    end

    def test_starts_with_ghost_executable
      command = GhostAdapter::Command.new(alter: '', table: '', database: '')
      assert_equal command.to_a[0], 'gh-ost'
    end

    def test_alter_arg
      alter = 'ADD COLUMN foos'
      command = GhostAdapter::Command.new(alter: alter, table: '', database: '')
      assert_includes command.to_a, "--alter=#{alter}"
    end

    def test_table_arg
      table = 'foos'
      command = GhostAdapter::Command.new(alter: '', table: table, database: '')
      assert_includes command.to_a, "--table=#{table}"
    end

    def test_database_arg
      db_name = 'testdbname'
      command = GhostAdapter::Command.new(alter: '', table: '', database: db_name)
      assert_includes command.to_a, "--database=#{db_name}"
    end

    def test_database_from_config
      db_name = 'testdbname'
      GhostAdapter.stub :config, GhostAdapter::Config.new(database: db_name) do
        command = GhostAdapter::Command.new(alter: '', table: '')
        assert_includes command.to_a, "--database=#{db_name}"
      end
    end

    def test_database_config_overwrites_arg
      db_config_name = 'config'
      db_arg_name = 'arg'
      GhostAdapter.stub :config, GhostAdapter::Config.new(database: db_config_name) do
        command = GhostAdapter::Command.new(alter: '', table: '', database: db_arg_name)
        assert_includes command.to_a, "--database=#{db_config_name}"
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
      command = GhostAdapter::Command.new(alter: '', table: '', database: '', dry_run: false)
      assert_includes command.to_a, '--execute'
    end

    def test_dry_run
      command = GhostAdapter::Command.new(alter: '', table: '', database: '', dry_run: true)
      refute_includes command.to_a, '--execute'
    end

    def test_alter_arg_missing
      assert_raises(ArgumentError, 'alter cannot be nil') do
        GhostAdapter::Command.new(table: '', database: '')
      end
    end

    def test_table_arg_missing
      assert_raises(ArgumentError, 'table cannot be nil') do
        GhostAdapter::Command.new(alter: '', database: '')
      end
    end

    def test_database_arg_and_config_missing
      assert_raises(ArgumentError, 'database cannot be nil') do
        GhostAdapter::Command.new(alter: '', table: '')
      end
    end
  end
end
