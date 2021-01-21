require 'active_record/connection_adapters/mysql2_adapter'

gem "mysql2", ">= 0.4.4", "< 0.6.0"
require "mysql2"

module ActiveRecord
  module ConnectionHandling
    # Establishes a connection to the database that's used by all Active Record objects.
    def ghost_mysql2_connection(config)
      config = config.symbolize_keys
      config[:flags] ||= 0

      if config[:flags].kind_of? Array
        config[:flags].push "FOUND_ROWS".freeze
      else
        config[:flags] |= Mysql2::Client::FOUND_ROWS
      end

      client = Mysql2::Client.new(config)
      ConnectionAdapters::GhostMysql2Adapter.new(client, logger, nil, config)
    rescue Mysql2::Error => error
      if error.message.include?("Unknown database")
        raise ActiveRecord::NoDatabaseError
      else
        raise
      end
    end
  end

  module ConnectionAdapters
    class GhostMysql2Adapter < Mysql2Adapter
      ADAPTER_NAME = 'ghost_mysql2'.freeze

      def execute(sql, name = nil)
        return if /\Aalter\stable/i =~ sql
        super(sql, name)
      end
    end
  end
end
