require 'test_helper'

module GhostAdapter
  class ConfigTest < MiniTest::Test
    def test_rejects_unknown_keys
      assert_raises(ArgumentError) { Config.new(unknown_key: 123) }
    end

    def tests_compact_removes_nil_keys
      options = { verbose: true }
      config = Config.new(options)
      assert_equal config.compact, options
    end

    def test_as_args_skips_false_values
      options = { verbose: false }
      config = Config.new(options)
      assert_equal config.as_args, []
    end

    def test_as_args_skips_nil_value
      options = { verbose: nil }
      config = Config.new(options)
      assert_equal config.as_args, []
    end

    def test_as_args_true_value
      options = { verbose: true }
      config = Config.new(options)
      assert_equal config.as_args.first, '--verbose'
    end

    def test_as_args_non_boolean_value
      options = { verbose: 100 }
      config = Config.new(options)
      assert_equal config.as_args.first, '--verbose=100'
    end

    def test_as_args_hyphenated_key
      options = { cut_over: 'default' }
      config = Config.new(options)
      assert_equal config.as_args.first, '--cut-over=default'
    end
  end
end
