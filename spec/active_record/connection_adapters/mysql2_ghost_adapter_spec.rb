require 'spec_helper'
require 'active_record/connection_adapters/abstract/connection_pool'

RSpec.describe ActiveRecord::ConnectionAdapters::Mysql2GhostAdapter do
  matcher :execute_sql do |sql|
    match do |adapter|
      expect(adapter).to receive(:execute).with(sql)
    end
  end

  let(:logger) { double(:logger, puts: true) }
  let(:mysql_client) { double('Mysql2::Client', query_options: {}, query: nil) }
  let(:table) { :foo }
  let(:column) { :bar_id }

  subject { described_class.new(mysql_client, logger, {}, {}) }

  before do
    allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(true)
    allow(mysql_client).to receive(:server_info).and_return({ id: 50_732, version: '5.7.32-log' })
    if Gem.loaded_specs['activerecord'].version < Gem::Version.new('6.1')
      allow(mysql_client).to receive(:escape).with(table.to_s).and_return(table.to_s)
      allow(mysql_client).to receive(:more_results?)
    end
    if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.1')
      allow(mysql_client).to receive(:closed?).and_return(false)
      allow(mysql_client).to receive(:ping).and_return(true)
      allow(mysql_client).to receive(:close)
    end
    if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.2')
      allow(GhostAdapter::VersionChecker).to receive(:validate_executable!)
      # AR 7.2's NullPool#server_version memoizes via a non-reentrant Mutex, which
      # deadlocks when a lone-connection double drives the real version lookup
      allow(subject).to receive(:supports_index_sort_order?).and_return(false)
    end
  end

  describe 'schema statements' do
    describe 'clean_query' do
      it 'parses query correctly' do
        sql =
          'ADD index_type INDEX `bar_index_name` (`bar_id`), ' \
          'ADD index_type INDEX `baz_index_name` (`baz_id`);;;'

        sanatized_sql =
          'ADD index_type INDEX `bar_index_name` (`bar_id`), ' \
          'ADD index_type INDEX `baz_index_name` (`baz_id`)'

        expect(GhostAdapter::Migrator).to receive(:execute)
          .with(table.to_s, sanatized_sql, any_args)

        subject.execute("ALTER TABLE #{table} #{sql}")
      end
    end

    describe 're-defined ActiveRecord methods' do
      before do
        allow(subject).to receive(:execute)
      end

      describe '#add_index' do
        context 'with no options' do
          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD INDEX `index_#{table}_on_#{column}` (`#{column}`)"
            subject.add_index(table, column)
          end
        end

        context 'with multiple columns' do
          let(:col2) { :baz_id }

          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD INDEX `index_#{table}_on_#{column}_and_#{col2}` (`#{column}`, `#{col2}`)"
            subject.add_index(table, [column, col2])
          end

          context 'with length option' do
            let(:length1) { rand(20) }
            let(:length2) { rand(20) }

            it 'passes the correct SQL to #execute' do
              expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD INDEX `index_#{table}_on_#{column}_and_#{col2}` (`#{column}`(#{length1}), `#{col2}`(#{length2}))"
              subject.add_index(table, [column, col2], length: { column.to_s => length1, col2.to_s => length2 })
            end
          end
        end

        context 'with unique option true' do
          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD UNIQUE INDEX `index_#{table}_on_#{column}` (`#{column}`)"
            subject.add_index(table, column, unique: true)
          end
        end

        context 'with name option' do
          let(:index_name) { 'index_name' }

          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD INDEX `#{index_name}` (`#{column}`)"
            subject.add_index(table, column, name: index_name)
          end
        end

        context 'with length option' do
          let(:length) { rand(20) }

          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD INDEX `index_#{table}_on_#{column}` (`#{column}`(#{length}))"
            subject.add_index(table, column, length: length)
          end
        end

        context 'with using option' do
          let(:method) { 'btree' }

          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD INDEX `index_#{table}_on_#{column}` USING #{method} (`#{column}`)"
            subject.add_index(table, column, using: method)
          end
        end

        context 'with type option' do
          let(:type) { 'fulltext' }

          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` ADD #{type.upcase} INDEX `index_#{table}_on_#{column}` (`#{column}`)"
            subject.add_index(table, column, type: type)
          end
        end
      end

      describe '#remove_index' do
        let(:index_name) { 'index_name' }

        before do
          # This must be mocked because the method tries to query the database to get the index name
          allow(subject).to receive(:index_name_for_remove).and_return(index_name)
        end

        context 'with column name passed as positional argument' do
          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` DROP INDEX `#{index_name}`"
            subject.remove_index(table, column)
          end
        end

        context 'with column name passed as keyword argument' do
          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` DROP INDEX `#{index_name}`"
            subject.remove_index(table, column: column)
          end
        end

        context 'with index name passed as keyword argument' do
          let(:index_name) { 'brand_new_index_name' }

          it 'passes the correct SQL to #execute' do
            expect(subject).to execute_sql "ALTER TABLE `#{table}` DROP INDEX `#{index_name}`"
            subject.remove_index(table, name: index_name)
          end
        end

        if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('6.1')
          context 'when ActiveRecord version is >= 6.1' do
            context 'with if_exists property set false' do
              context 'when index exists' do
                before { allow(subject).to receive(:index_exists?).and_return(true) }

                it 'passes the correct SQL to #execute' do
                  expect(subject).to execute_sql "ALTER TABLE `#{table}` DROP INDEX `#{index_name}`"
                  subject.remove_index(table, column, if_exists: true)
                end
              end

              context 'when index does not exist' do
                before { allow(subject).to receive(:index_exists?).and_return(false) }

                it 'does nothing' do
                  subject.remove_index(table, column, if_exists: true)
                  expect(subject).not_to have_received(:execute)
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'bug fixes' do
    describe 'DROP_TABLE_PATTERN' do
      it 'matches DROP TABLE statements' do
        expect(subject.send(:create_or_drop_table?, 'DROP TABLE `foo`')).to be_truthy
      end
    end

    describe '#execute keyword argument' do
      it 'declares the keyword accepted by the underlying activerecord version' do
        parameters = described_class.instance_method(:execute).parameters

        if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.1')
          expect(parameters).to include(%i[key allow_retry])
          expect(parameters).not_to include(%i[key async])
        elsif Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.0')
          expect(parameters).to include(%i[key async])
        end
      end

      if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.0')
        it 'passes a non-ALTER TABLE statement through without raising' do
          allow(mysql_client).to receive(:close)
          allow(mysql_client).to receive(:abandon_results!)

          expect { subject.execute('SELECT 1') }.not_to raise_error
        end
      end
    end
  end

  if Gem.loaded_specs['activerecord'].version >= Gem::Version.new('7.2')
    describe 'ActiveRecord >= 7.2 support' do
      describe 'adapter registration' do
        it 'registers itself with ActiveRecord::ConnectionAdapters' do
          expect(ActiveRecord::ConnectionAdapters.resolve('mysql2_ghost')).to eq(described_class)
        end

        it 'instantiates via ActiveRecord::DatabaseConfigurations::HashConfig#new_connection' do
          config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            'test', 'primary', { adapter: 'mysql2_ghost', database: 'my_db' }
          )

          connection = config.new_connection

          expect(connection).to be_a(described_class)
          expect(connection.send(:database)).to eq('my_db')
        end
      end

      describe '#initialize' do
        def new_adapter_connection
          config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            'test', 'primary', { adapter: 'mysql2_ghost', database: 'my_db' }
          )
          config.new_connection
        end

        around do |example|
          original_skip = ENV.fetch('SKIP_GHOST_VERSION_CHECK', nil)
          original_dry_run = ENV.fetch('DRY_RUN', nil)
          example.run
          ENV['SKIP_GHOST_VERSION_CHECK'] = original_skip
          ENV['DRY_RUN'] = original_dry_run
        end

        context 'when ghost migration is enabled and SKIP_GHOST_VERSION_CHECK is not set' do
          before { ENV['SKIP_GHOST_VERSION_CHECK'] = nil }

          it 'validates the gh-ost executable' do
            expect(GhostAdapter::VersionChecker).to receive(:validate_executable!)
            new_adapter_connection
          end
        end

        context 'when SKIP_GHOST_VERSION_CHECK is set to 1' do
          before { ENV['SKIP_GHOST_VERSION_CHECK'] = '1' }

          it 'does not validate the gh-ost executable' do
            expect(GhostAdapter::VersionChecker).not_to receive(:validate_executable!)
            new_adapter_connection
          end
        end

        context 'when DRY_RUN is set to 1' do
          before { ENV['DRY_RUN'] = '1' }

          it 'sets dry_run to true' do
            connection = new_adapter_connection
            expect(connection.send(:dry_run)).to be true
          end
        end
      end

      describe 'ghost_migration_enabled? guard' do
        before { allow(mysql_client).to receive(:abandon_results!) }

        context 'when disabled' do
          before { allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(false) }

          it '#execute delegates to the native implementation instead of gh-ost' do
            expect(GhostAdapter::Migrator).not_to receive(:execute)
            subject.execute("ALTER TABLE #{table} ADD INDEX index_name (bar_id)")
          end

          it '#add_index falls back to native CREATE INDEX syntax' do
            allow(subject).to receive(:execute)
            subject.add_index(table, column)
            expect(subject).to have_received(:execute).with("CREATE INDEX `index_#{table}_on_#{column}` ON `#{table}` (`#{column}`)")
          end

          it '#remove_index falls back to native DROP INDEX syntax' do
            allow(subject).to receive(:index_name_for_remove).and_return('index_name')
            allow(subject).to receive(:execute)
            subject.remove_index(table, column)
            expect(subject).to have_received(:execute).with("DROP INDEX `index_name` ON `#{table}`")
          end
        end

        context 'when enabled' do
          before { allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(true) }

          it '#add_index still forces ALTER TABLE syntax' do
            allow(subject).to receive(:execute)
            subject.add_index(table, column)
            expect(subject).to have_received(:execute).with("ALTER TABLE `#{table}` ADD INDEX `index_#{table}_on_#{column}` (`#{column}`)")
          end
        end
      end
    end
  end
end
