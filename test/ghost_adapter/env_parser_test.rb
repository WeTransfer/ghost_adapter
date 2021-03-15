require 'test_helper'

module GhostAdapter
  class EnvParserTest < MiniTest::Test
    def test_should_ignore_non_ghost_keys
      env = { 'ENV_VALUE' => '1', 'VERBOSE' => 'true' }
      config = EnvParser.new(env).config
      refute config.any?
    end

    def test_reads_string_key
      env = { 'GHOST_DEBUG' => 'test' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], 'test'
    end

    def test_reads_int_key
      env = { 'GHOST_DEBUG' => '123' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], 123
    end

    def test_reads_float_key
      env = { 'GHOST_DEBUG' => '123' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], 123
    end

    def test_reads_boolean_y_key
      env = { 'GHOST_DEBUG' => 'y' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], true
    end

    def test_reads_boolean_yes_key
      env = { 'GHOST_DEBUG' => 'yes' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], true
    end

    def test_reads_boolean_t_key
      env = { 'GHOST_DEBUG' => 't' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], true
    end

    def test_reads_boolean_true_key
      env = { 'GHOST_DEBUG' => 'true' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], true
    end

    def test_reads_boolean_n_key
      env = { 'GHOST_DEBUG' => 'n' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], false
    end

    def test_reads_boolean_no_key
      env = { 'GHOST_DEBUG' => 'no' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], false
    end

    def test_reads_boolean_f_key
      env = { 'GHOST_DEBUG' => 'f' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], false
    end

    def test_reads_boolean_false_key
      env = { 'GHOST_DEBUG' => 'false' }
      config = EnvParser.new(env).config
      assert_equal config[:debug], false
    end

    def test_reads_boolean_case_insensitive
      env = { 'GHOST_VERBOSE' => 'TRUE', 'GHOST_DEBUG' => 'NO' }
      config = EnvParser.new(env).config
      assert_equal config[:verbose], true
      assert_equal config[:debug], false
    end
  end
end
