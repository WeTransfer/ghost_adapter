require 'spec_helper'
require 'active_record/connection_adapters/abstract/connection_pool'

RSpec.describe ActiveRecord::ConnectionAdapters::Mysql2GhostAdapter do
  let(:logger) { double(:logger, puts: true) }
  let(:mysql_client) { double('Mysql2::Client', query_options: {}, query: nil) }

  subject { described_class.new(mysql_client, logger, {}, {}) }

  describe 'schema statements' do
    describe 'clean_query' do
      let(:table_name) { 'foo' }

      it 'parses query correctly' do
        sql =
          'ADD index_type INDEX `bar_index_name` (`bar_id`), '\
          'ADD index_type INDEX `baz_index_name` (`baz_id`);;;'

        sanatized_sql =
          'ADD index_type INDEX bar_index_name (bar_id), '\
          'ADD index_type INDEX baz_index_name (baz_id)'

        expect(GhostAdapter::Migrator).to receive(:execute)
          .with(table_name, sanatized_sql, any_args)

        subject.execute("ALTER TABLE #{table_name} #{sql}")
      end
    end

    describe '#add_index' do
      let(:table_name) { :foo }
      let(:column_name) { :bar_id }
      let(:options) { {} }
      let(:sql) { 'ADD index_type INDEX `index_name` (`bar_id`)' }

      before do
        allow(subject).to(
          receive(:add_index_options)
          .with(table_name, column_name, options)
          .and_return(['index_name', 'index_type', "`#{column_name}`"])
        )
      end

      it 'passes the built SQL to #execute' do
        expect(subject).to(
          receive(:execute)
          .with(
            "ALTER TABLE `#{table_name}` ADD index_type INDEX `index_name` (`bar_id`)"
          )
        )
        subject.add_index(table_name, column_name, options)
      end
    end

    describe '#remove_index' do
      let(:table_name) { :foo }
      let(:options) { { column: :bar_id } }
      let(:sql) { 'DROP INDEX `index_name`' }

      before do
        allow(subject).to(
          receive(:index_name_for_remove)
          .with(table_name, options)
          .and_return('index_name')
        )
      end

      it 'passes the built SQL to #execute' do
        expect(subject).to(
          receive(:execute)
          .with("ALTER TABLE `#{table_name}` DROP INDEX `index_name`")
        )
        subject.remove_index(table_name, options)
      end
    end
  end
end
