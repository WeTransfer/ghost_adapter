require 'spec_helper'
require 'active_record/connection_adapters/abstract/connection_pool'
require 'active_record/database_configurations'

RSpec.describe ActiveRecord::ConnectionAdapters::Mysql2GhostAdapter do
  matcher :execute_sql do |sql|
    match do |adapter|
      expect(adapter).to receive(:execute).with(sql)
    end
  end

  let(:mysql_client) { double('Mysql2::Client', query_options: {}, query: nil, affected_rows: 1, abandon_results!: nil, ping: true) }
  let(:table) { :foo }
  let(:column) { :bar_id }

  let(:configuration) { { adapter: 'mysql2_ghost', database: 'ghost_adapter_test' } }

  around(:each, :dry_run) do |example|
    previous_value = ENV.fetch('DRY_RUN', nil)
    ENV['DRY_RUN'] = '1'
    example.run
  ensure
    ENV['DRY_RUN'] = previous_value
  end

  subject do
    described_class.new(configuration).tap do |adapter|
      adapter.instance_variable_set(:@raw_connection, mysql_client)
    end
  end

  before do
    allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(true)
    allow(GhostAdapter::VersionChecker).to receive(:validate_executable!)
    allow(mysql_client).to receive(:closed?).and_return(false)
    allow(mysql_client).to receive(:server_info).and_return({ id: 50_732, version: '5.7.32-log' })
    allow(subject.pool).to receive(:role).and_return(:writing)
    allow(subject.pool).to receive(:shard).and_return(:default)
  end

  describe 'Rails 7.2 adapter registration' do
    it 'registers the adapter without the legacy connection hook' do
      expect(ActiveRecord::ConnectionAdapters.resolve('mysql2_ghost')).to eq(described_class)
      expect(ActiveRecord::ConnectionHandling).not_to be_method_defined(:mysql2_ghost_connection)
    end

    it 'initializes from a single configuration hash' do
      database_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
        'test', 'primary', configuration
      )

      adapter = database_config.new_connection

      expect(adapter).to be_a(described_class)
      expect(adapter.adapter_name).to eq('mysql2_ghost')
      expect(adapter.send(:database)).to eq('ghost_adapter_test')
    end

    it 'does not validate gh-ost while creating the adapter' do
      expect(GhostAdapter::VersionChecker).not_to receive(:validate_executable!)

      described_class.new(configuration)
    end

    it 'validates gh-ost immediately before the first migration and only once' do
      expect(GhostAdapter::VersionChecker).to receive(:validate_executable!).once.ordered
      expect(GhostAdapter::Migrator).to receive(:execute)
        .with('widgets', 'ADD INDEX `index_widgets_on_name` (`name`)', 'ghost_adapter_test', false).twice.ordered

      subject.execute('ALTER TABLE `widgets` ADD INDEX `index_widgets_on_name` (`name`)')
      subject.execute('ALTER TABLE `widgets` ADD INDEX `index_widgets_on_name` (`name`)')
    end

    it 'bypasses gh-ost validation when configured' do
      allow(ENV).to receive(:fetch).with('SKIP_GHOST_VERSION_CHECK', nil).and_return('1')

      expect(GhostAdapter::VersionChecker).not_to receive(:validate_executable!)
      expect(GhostAdapter::Migrator).to receive(:execute)
        .with('widgets', 'ADD INDEX `index_widgets_on_name` (`name`)', 'ghost_adapter_test', false)

      subject.execute('ALTER TABLE `widgets` ADD INDEX `index_widgets_on_name` (`name`)')
    end

    it 'routes ALTER TABLE through gh-ost with the configured database' do
      expect(GhostAdapter::Migrator).to receive(:execute)
        .with('widgets', 'ADD INDEX `index_widgets_on_name` (`name`)', 'ghost_adapter_test', false)

      subject.execute('ALTER TABLE `widgets` ADD INDEX `index_widgets_on_name` (`name`)')
    end

    it 'uses Rails native CREATE INDEX behavior when ghost migrations are disabled' do
      allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(false)
      expect(subject).to receive(:execute)
        .with('CREATE INDEX `index_foo_on_bar_id` ON `foo` (`bar_id`)').and_return(:native)

      expect(GhostAdapter::Migrator).not_to receive(:execute)
      expect(subject.add_index(table, column)).to eq(:native)
    end

    it 'delegates raw ALTER TABLE to mysql2 when ghost migrations are disabled' do
      allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(false)

      expect(GhostAdapter::VersionChecker).not_to receive(:validate_executable!)
      expect(GhostAdapter::Migrator).not_to receive(:execute)
      expect(mysql_client).to receive(:query).with('ALTER TABLE `widgets` ADD INDEX `index_widgets_on_name` (`name`)')

      subject.execute('ALTER TABLE `widgets` ADD INDEX `index_widgets_on_name` (`name`)')
    end

    it 'delegates remove_index to Rails native behavior when ghost migrations are disabled' do
      allow(GhostAdapter::Internal).to receive(:ghost_migration_enabled?).and_return(false)
      allow(subject).to receive(:index_name_for_remove).and_return('index_foo_on_bar_id')
      expect(subject).to receive(:execute)
        .with('DROP INDEX `index_foo_on_bar_id` ON `foo`').and_return(:native)

      expect(GhostAdapter::VersionChecker).not_to receive(:validate_executable!)
      expect(GhostAdapter::Migrator).not_to receive(:execute)
      expect(subject.remove_index(table, column)).to eq(:native)
    end

    it 'routes add_index through gh-ost' do
      expect(GhostAdapter::Migrator).to receive(:execute)
        .with('foo', 'ADD INDEX `index_foo_on_bar_id` (`bar_id`)', 'ghost_adapter_test', false)

      subject.add_index(table, column)
    end

    it 'routes remove_index through gh-ost' do
      allow(subject).to receive(:index_name_for_remove).and_return('index_foo_on_bar_id')
      expect(GhostAdapter::Migrator).to receive(:execute)
        .with('foo', 'DROP INDEX `index_foo_on_bar_id`', 'ghost_adapter_test', false)

      subject.remove_index(table, column)
    end

    it 'skips CREATE and DROP TABLE statements during dry runs', :dry_run do
      adapter = described_class.new(configuration)

      expect(GhostAdapter::Migrator).not_to receive(:execute)
      expect { adapter.execute('CREATE TABLE `widgets` (`id` bigint)') }
        .to output("Skipping CREATE TABLE or DROP TABLE for dry run\nSQL:\nCREATE TABLE `widgets` (`id` bigint)\n").to_stdout
      expect { adapter.execute('DROP TABLE `widgets`') }
        .to output("Skipping CREATE TABLE or DROP TABLE for dry run\nSQL:\nDROP TABLE `widgets`\n").to_stdout
    end

    it 'suppresses only schema migration writes through Rails 7.2 insert and delete APIs', :dry_run do
      adapter = described_class.new(configuration)

      expect(adapter.exec_insert('INSERT INTO `schema_migrations` (`version`) VALUES (20260811123456)')).to be_nil
      expect(adapter.exec_delete('DELETE FROM `schema_migrations` WHERE `version` = 20260811123456')).to eq(0)
    end

    it 'suppresses schema migration writes for a custom schema_migrations_table_name', :dry_run do
      previous_table_name = ActiveRecord::Base.schema_migrations_table_name
      ActiveRecord::Base.schema_migrations_table_name = 'custom_migrations'

      adapter = described_class.new(configuration)

      expect(adapter.exec_insert('INSERT INTO `custom_migrations` (`version`) VALUES (20260811123456)')).to be_nil
      expect(adapter.exec_delete('DELETE FROM `custom_migrations` WHERE `version` = 20260811123456')).to eq(0)
    ensure
      ActiveRecord::Base.schema_migrations_table_name = previous_table_name
    end

    it 'delegates unrelated dry-run DML to mysql2', :dry_run do
      adapter = described_class.new(configuration)
      adapter.instance_variable_set(:@raw_connection, mysql_client)
      allow(adapter.pool).to receive(:role).and_return(:writing)
      allow(adapter.pool).to receive(:shard).and_return(:default)

      expect(mysql_client).to receive(:query).with("INSERT INTO `widgets` (`name`) VALUES ('test')")
      expect(adapter.exec_insert("INSERT INTO `widgets` (`name`) VALUES ('test')")).to be_a(ActiveRecord::Result)
      expect(mysql_client).to receive(:query).with("DELETE FROM `widgets` WHERE `name` = 'test'")
      expect(adapter.exec_delete("DELETE FROM `widgets` WHERE `name` = 'test'")).to eq(1)
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

        context 'with if_exists property set' do
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
