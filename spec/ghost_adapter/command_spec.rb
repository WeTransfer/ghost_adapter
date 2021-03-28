require 'spec_helper'
require 'ghost_adapter/command'

RSpec.describe GhostAdapter::Command do
  before(:each) do
    GhostAdapter.clear_config
  end

  it 'always starts with gh-ost executable' do
    command = described_class.new(alter: '', table: '', database: '')
    expect(command.to_a[0]).to eq('gh-ost')
  end

  describe 'constructor arguments' do
    it 'sets the alter argument' do
      alter = 'ADD COLUMN foos'
      command = described_class.new(alter: alter, table: '', database: '')
      expect(command.to_a).to include "--alter=#{alter}"
    end

    it 'sets the table argument' do
      table = 'foos'
      command = described_class.new(alter: '', table: table, database: '')
      expect(command.to_a).to include "--table=#{table}"
    end

    it 'sets the database argument' do
      db_name = 'testdbname'
      command = described_class.new(alter: '', table: '', database: db_name)
      expect(command.to_a).to include "--database=#{db_name}"
    end

    it 'sets the execute argument when dry run is false' do
      command = described_class.new(alter: '', table: '', database: '', dry_run: false)
      expect(command.to_a).to include '--execute'
    end

    it 'omits the execute argument when dry run is true' do
      command = described_class.new(alter: '', table: '', database: '', dry_run: true)
      expect(command.to_a).not_to include '--execute'
    end

    context 'missing arguments' do
      it 'raises error when alter argument is missing' do
        expect do
          described_class.new(table: '', database: '')
        end.to raise_error(ArgumentError, /missing keyword: :{0,1}alter/)
      end

      it 'raises error when table argument is missing' do
        expect do
          described_class.new(alter: '', database: '')
        end.to raise_error(ArgumentError, /missing keyword: :{0,1}table/)
      end

      it 'raises error when database argument (and config) is missing' do
        expect do
          described_class.new(alter: '', table: '')
        end.to raise_error(ArgumentError, 'database cannot be nil')
      end
    end
  end

  describe 'configuration arguments' do
    it 'gets the database name from configuration' do
      db_name = 'testdbname'
      allow(GhostAdapter).to receive(:config).and_return GhostAdapter::Config.new(database: db_name)

      command = described_class.new(alter: '', table: '')
      expect(command.to_a).to include "--database=#{db_name}"
    end

    it 'overwrites database constructor argument with configuration value' do
      db_config_name = 'config'
      db_arg_name = 'arg'
      allow(GhostAdapter).to receive(:config).and_return GhostAdapter::Config.new(database: db_config_name)

      command = described_class.new(alter: '', table: '', database: db_arg_name)
      expect(command.to_a).to include "--database=#{db_config_name}"
    end

    it 'sets other argument values from configuration' do
      config = GhostAdapter::Config.new(verbose: true, database: 'db', max_load: 1200)
      allow(GhostAdapter).to receive(:config).and_return config
      command = described_class.new(alter: '', table: '')

      expect(command.to_a).to include '--verbose'
      expect(command.to_a).to include '--max-load=1200'
    end
  end
end
