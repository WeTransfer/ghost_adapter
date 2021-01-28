require 'test_helper'

module GhostAdapter
  class EnvParserTest < MiniTest::Test
    def test_should_ignore_non_ghost_keys
      env = { 'ENV_VALUE' => '1', 'VERBOSE' => 'true' }
      config = EnvParser.new(env).config
      refute config.any?
    end

    def test_reads_string_key
      env = { 'GHOST_KEY' => 'test' }
      config = EnvParser.new(env).config
      assert_equal config['key'], 'test'
    end

    def test_reads_int_key
      env = { 'GHOST_KEY' => '123' }
      config = EnvParser.new(env).config
      assert_equal config['key'], 123
    end

    def test_reads_float_key
      env = { 'GHOST_KEY' => '123' }
      config = EnvParser.new(env).config
      assert_equal config['key'], 123
    end

    def test_reads_boolean_y_key
      env = { 'GHOST_KEY' => 'y' }
      config = EnvParser.new(env).config
      assert_equal config['key'], true
    end

    def test_reads_boolean_yes_key
      env = { 'GHOST_KEY' => 'yes' }
      config = EnvParser.new(env).config
      assert_equal config['key'], true
    end

    def test_reads_boolean_t_key
      env = { 'GHOST_KEY' => 't' }
      config = EnvParser.new(env).config
      assert_equal config['key'], true
    end

    def test_reads_boolean_true_key
      env = { 'GHOST_KEY' => 'true' }
      config = EnvParser.new(env).config
      assert_equal config['key'], true
    end

    def test_reads_boolean_n_key
      env = { 'GHOST_KEY' => 'n' }
      config = EnvParser.new(env).config
      assert_equal config['key'], false
    end

    def test_reads_boolean_no_key
      env = { 'GHOST_KEY' => 'no' }
      config = EnvParser.new(env).config
      assert_equal config['key'], false
    end

    def test_reads_boolean_f_key
      env = { 'GHOST_KEY' => 'f' }
      config = EnvParser.new(env).config
      assert_equal config['key'], false
    end

    def test_reads_boolean_false_key
      env = { 'GHOST_KEY' => 'false' }
      config = EnvParser.new(env).config
      assert_equal config['key'], false
    end

    def test_reads_boolean_case_insensitive
      env = { 'GHOST_TRUE' => 'TRUE', 'GHOST_NO' => 'NO' }
      config = EnvParser.new(env).config
      assert_equal config['true'], true
      assert_equal config['no'], false
    end
  end
end
