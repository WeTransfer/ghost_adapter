require 'test_helper'

describe GhostAdapter do
  describe '.setup' do
    it 'should create an empty config when no args are given' do
      GhostAdapter.setup

      assert_equal GhostAdapter.config.compact, {}
    end

    describe 'with hash argument' do
      it 'should accept a set of pre-defined configuration keys' do
        all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h
        GhostAdapter.setup(all_keys)

        assert_equal GhostAdapter.config.compact, all_keys
      end

      it 'should raise an ArgumentError if an unknown configuration key is given' do
        assert_raises(ArgumentError) { GhostAdapter.setup({ unknown_key: true }) }
      end
    end

    describe 'with block given' do
      it 'should accept a set of pre-defined configuration keys as methods' do
        all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h

        GhostAdapter.setup do |config|
          all_keys.each do |k, v|
            config.send("#{k}=", v)
          end
        end

        assert_equal GhostAdapter.config.compact, all_keys
      end

      it 'should raise a NoMethodError if an unknown configuration key is given' do
        assert_raises(NoMethodError) do
          GhostAdapter.setup { |config| config.unknown_key = true }
        end
      end
    end

    describe 'with hash argument and block given' do
      it 'will overwrite hash values with the values given in the block' do
        hash_keys = GhostAdapter::CONFIG_KEYS.take(2).map { |k| [k, true] }.to_h
        block_keys = GhostAdapter::CONFIG_KEYS.take(2).map { |k| [k, false] }.to_h

        GhostAdapter.setup(hash_keys) do |config|
          block_keys.each do |k, v|
            config.send("#{k}=", v)
          end
        end

        assert_equal GhostAdapter.config.compact, block_keys
      end

      it 'will not overwrite hash values if the same keys are not passed in the block' do
        first_key = GhostAdapter::CONFIG_KEYS[0]
        second_key = GhostAdapter::CONFIG_KEYS[1]

        GhostAdapter.setup({ first_key => 'first_key' }) do |config|
          config.send("#{second_key}=", 'second_key')
        end

        assert_equal GhostAdapter.config.compact, { first_key => 'first_key', second_key => 'second_key' }
      end
    end
  end
end
