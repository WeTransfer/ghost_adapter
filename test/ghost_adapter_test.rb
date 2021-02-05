require 'test_helper'

class GhostAdapterTest < MiniTest::Test
  def test_setup_empty
    GhostAdapter.clear_config
    GhostAdapter.setup

    assert_equal GhostAdapter.config.compact, {}
  end

  def test_setup_with_hash_arguments_accepts_predefined_keys
    GhostAdapter.clear_config

    all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h
    GhostAdapter.setup(all_keys)

    assert_equal GhostAdapter.config.compact, all_keys
  end

  def test_setup_with_hash_arguments_raises_error_on_unknown_key
    assert_raises(ArgumentError) { GhostAdapter.setup({ unknown_key: true }) }
  end

  def test_setup_with_block_accepts_predefined_methods
    GhostAdapter.clear_config

    all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h

    GhostAdapter.setup do |config|
      all_keys.each do |k, v|
        config.send("#{k}=", v)
      end
    end

    assert_equal GhostAdapter.config.compact, all_keys
  end

  def test_setup_with_block_raises_error_on_unknown_method
    assert_raises(NoMethodError) do
      GhostAdapter.setup { |config| config.unknown_key = true }
    end
  end

  def test_setup_with_hash_and_block_overrides_hash_values_for_same_key
    GhostAdapter.clear_config

    hash_keys = GhostAdapter::CONFIG_KEYS.take(2).map { |k| [k, true] }.to_h
    block_keys = GhostAdapter::CONFIG_KEYS.take(2).map { |k| [k, false] }.to_h

    GhostAdapter.setup(hash_keys) do |config|
      block_keys.each do |k, v|
        config.send("#{k}=", v)
      end
    end

    assert_equal GhostAdapter.config.compact, block_keys
  end

  def test_setup_with_hash_and_block_does_not_override_hash_values_for_different_keys
    GhostAdapter.clear_config

    first_key = GhostAdapter::CONFIG_KEYS[0]
    second_key = GhostAdapter::CONFIG_KEYS[1]

    GhostAdapter.setup({ first_key => 'first_key' }) do |config|
      config.send("#{second_key}=", 'second_key')
    end

    assert_equal GhostAdapter.config.compact, { first_key => 'first_key', second_key => 'second_key' }
  end

  # rubocop:disable Metrics/AbcSize
  def test_setup_called_twice
    GhostAdapter.clear_config

    keys = GhostAdapter::CONFIG_KEYS.sample(2)

    GhostAdapter.setup({ keys[0] => 'first', keys[1] => 'first' })
    config = GhostAdapter.config.compact
    assert_equal 'first', config[keys[0]]
    assert_equal 'first', config[keys[1]]

    GhostAdapter.setup({ keys[0] => 'second' })

    config = GhostAdapter.config.compact
    assert_equal 'second', config[keys[0]]
    assert_equal 'first', config[keys[1]]
  end
  # rubocop:enable Metrics/AbcSize
end
