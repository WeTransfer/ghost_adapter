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
    allow(mysql_client).to receive(:server_info).and_return({ id: 50_732, version: '5.7.32-log' })
    if Gem.loaded_specs['activerecord'].version < Gem::Version.new('6.1')
      allow(mysql_client).to receive(:escape).with(table.to_s).and_return(table.to_s)
      allow(mysql_client).to receive(:more_results?)
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
end
