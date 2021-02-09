require 'test_helper'

module GhostAdapter
  class ConfigTest < MiniTest::Test
    def test_rejects_unknown_keys
      assert_raises(ArgumentError) { Config.new(unknown_key: 123) }
    end

    def test_compact_removes_nil_keys
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

    def test_merge_overlapping_keys
      c1 = Config.new(verbose: true)
      c2 = Config.new(verbose: false)
      new_config = c1.merge!(c2)

      assert_equal new_config.verbose, c2.verbose
    end

    def test_merge_no_overlapping_keys
      c1 = Config.new(cut_over: 'default')
      c2 = Config.new(verbose: false)
      new_config = c1.merge!(c2)

      assert_equal new_config.cut_over, c1.cut_over
      assert_equal new_config.verbose, c2.verbose
    end

    def test_merge_mutates_self
      c1 = Config.new(cut_over: 'default')
      c2 = Config.new(verbose: false)
      c1.merge!(c2)

      assert_equal c1.verbose, c2.verbose
    end
  end
end
