require 'spec_helper'

RSpec.describe GhostAdapter::Config do
  describe 'constructor' do
    it 'rejects unknown keys' do
      expect { described_class.new(unknown_key: 123) }.to raise_error(ArgumentError)
    end
  end

  describe '#compact' do
    it 'removes keys with nil values' do
      options = { verbose: true }
      config = described_class.new(options)
      expect(config.compact).to eq options
    end
  end

  describe '#as_args' do
    it 'skips false values' do
      options = { verbose: false }
      config = described_class.new(options)
      expect(config.as_args).to eq []
    end

    it 'skips nil values' do
      options = { verbose: nil }
      config = described_class.new(options)
      expect(config.as_args).to eq []
    end

    it 'exclues the = for true values' do
      options = { verbose: true }
      config = described_class.new(options)
      expect(config.as_args).to include '--verbose'
    end

    it 'includes the = for non boolean values' do
      options = { verbose: 100 }
      config = described_class.new(options)
      expect(config.as_args).to include '--verbose=100'
    end

    it 'hyphenates multi-word keys' do
      options = { cut_over: 'default' }
      config = described_class.new(options)
      expect(config.as_args).to include '--cut-over=default'
    end
  end

  describe '#merge!' do
    it 'overwrites existing keys when both configs have value for same key' do
      c1 = described_class.new(verbose: true)
      c2 = described_class.new(verbose: false)
      new_config = c1.merge!(c2)

      expect(new_config.verbose).to eq c2.verbose
    end

    it 'does not overwrite existing keys when both configs to not have value for same key' do
      c1 = described_class.new(cut_over: 'default')
      c2 = described_class.new(verbose: false)
      new_config = c1.merge!(c2)

      expect(new_config.cut_over).to eq c1.cut_over
      expect(new_config.verbose).to eq c2.verbose
    end

    it 'mutates the caller' do
      c1 = described_class.new(cut_over: 'default')
      c2 = described_class.new(verbose: false)
      c1.merge!(c2)

      expect(c1.verbose).to eq c2.verbose
    end
  end
end
