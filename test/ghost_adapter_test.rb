require 'test_helper'

class GhostAdapterTest < MiniTest::Test
  def test_setup_empty
    GhostAdapter.setup

    assert_equal GhostAdapter.config.compact, {}
  end

  def test_setup_with_hash_arguments_accepts_predefined_keys
    all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h
    GhostAdapter.setup(all_keys)

    assert_equal GhostAdapter.config.compact, all_keys
  end

  def test_setup_with_hash_arguments_raises_error_on_unknown_key
    assert_raises(ArgumentError) { GhostAdapter.setup({ unknown_key: true }) }
  end

  def test_setup_with_block_accepts_predefined_methods
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
    first_key = GhostAdapter::CONFIG_KEYS[0]
    second_key = GhostAdapter::CONFIG_KEYS[1]

    GhostAdapter.setup({ first_key => 'first_key' }) do |config|
      config.send("#{second_key}=", 'second_key')
    end

    assert_equal GhostAdapter.config.compact, { first_key => 'first_key', second_key => 'second_key' }
  end
end
