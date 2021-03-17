# frozen_string_literal: true

RSpec.describe GhostAdapter do
  it 'has a version number' do
    expect(GhostAdapter::VERSION).not_to be nil
  end

  describe 'setup' do
    before(:each) do
      described_class.clear_config
    end

    it 'accepts an empty setup' do
      described_class.setup
      expect(described_class.config.compact).to eq({})
    end

    context 'with hash arguments' do
      it 'accepts a predefined set of keys' do
        all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h
        described_class.setup(all_keys)

        expect(described_class.config.compact).to eq all_keys
      end

      it 'raises error on an unknown config key' do
        expect { described_class.setup({ unknown_key: 0 }) }.to raise_error(ArgumentError)
      end
    end

    context 'with block' do
      it 'accepts a predefined set of keys as methods' do
        all_keys = GhostAdapter::CONFIG_KEYS.map.with_index { |k, v| [k, v] }.to_h

        described_class.setup do |config|
          all_keys.each do |k, v|
            config.send("#{k}=", v)
          end
        end

        expect(described_class.config.compact).to eq all_keys
      end

      it 'raises error on an unknown config key' do
        expect { described_class.setup { |c| c.unknown_key = 0 } }.to raise_error(NoMethodError)
      end
    end

    context 'with hash arguments and block' do
      it 'overrides hash values with block values for same key' do
        hash_keys = GhostAdapter::CONFIG_KEYS.take(2).map { |k| [k, true] }.to_h
        block_keys = GhostAdapter::CONFIG_KEYS.take(2).map { |k| [k, false] }.to_h

        described_class.setup(hash_keys) do |config|
          block_keys.each do |k, v|
            config.send("#{k}=", v)
          end
        end

        expect(described_class.config.compact).to eq block_keys
      end

      it 'does not override hash values with block values for different keys' do
        first_key = GhostAdapter::CONFIG_KEYS[0]
        second_key = GhostAdapter::CONFIG_KEYS[1]

        described_class.setup({ first_key => 'first_key' }) do |config|
          config.send("#{second_key}=", 'second_key')
        end

        expect(described_class.config.compact).to eq({ first_key => 'first_key', second_key => 'second_key' })
      end
    end

    context 'multiple calls' do
      it 'overrides values for the same keys from the first call with the second' do
        keys = GhostAdapter::CONFIG_KEYS.sample(2)

        described_class.setup({ keys[0] => 'first', keys[1] => 'first' })
        config = described_class.config.compact
        expect('first').to eq config[keys[0]]
        expect('first').to eq config[keys[1]]

        described_class.setup({ keys[0] => 'second' })

        config = described_class.config.compact
        expect('second').to eq config[keys[0]]
        expect('first').to eq config[keys[1]]
      end
    end
  end
end
