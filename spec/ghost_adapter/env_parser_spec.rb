require 'spec_helper'

RSpec.describe GhostAdapter::EnvParser do
  it 'ignores non gh-ost keys' do
    env = { 'ENV_VALUE' => '1', 'VERBOSE' => 'true' }
    config = described_class.new(env).config
    expect(config.any?).to be false
  end

  context 'string values' do
    it 'reads string values and does no conversion' do
      env = { 'GHOST_KEY' => 'test' }
      config = described_class.new(env).config
      expect(config['key']).to eq 'test'
    end
  end

  context 'converting number values' do
    it 'converts integer values' do
      env = { 'GHOST_KEY' => '123' }
      config = described_class.new(env).config
      expect(config['key']).to eq 123
    end

    it 'converts float values' do
      env = { 'GHOST_KEY' => '1.23' }
      config = described_class.new(env).config
      expect(config['key']).to eq 1.23
    end
  end

  context 'converting boolean values' do
    it 'converts "y" to true' do
      env = { 'GHOST_KEY' => 'y' }
      config = described_class.new(env).config
      expect(config['key']).to be true
    end

    it 'converts "yes" to true' do
      env = { 'GHOST_KEY' => 'yes' }
      config = described_class.new(env).config
      expect(config['key']).to be true
    end

    it 'converts "t" to true' do
      env = { 'GHOST_KEY' => 't' }
      config = described_class.new(env).config
      expect(config['key']).to be true
    end

    it 'converts "true" to true' do
      env = { 'GHOST_KEY' => 'true' }
      config = described_class.new(env).config
      expect(config['key']).to be true
    end

    it 'converts "n" to false' do
      env = { 'GHOST_KEY' => 'n' }
      config = described_class.new(env).config
      expect(config['key']).to be false
    end

    it 'converts "no" to false' do
      env = { 'GHOST_KEY' => 'no' }
      config = described_class.new(env).config
      expect(config['key']).to be false
    end

    it 'converts "f" to false' do
      env = { 'GHOST_KEY' => 'f' }
      config = described_class.new(env).config
      expect(config['key']).to be false
    end

    it 'converts "false" to false' do
      env = { 'GHOST_KEY' => 'false' }
      config = described_class.new(env).config
      expect(config['key']).to be false
    end
  end
end
