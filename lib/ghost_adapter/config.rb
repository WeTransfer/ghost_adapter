require 'ghost_adapter/env_parser'

module GhostAdapter
  CONFIG_KEYS = %i[aliyun_rds
                   allow_master_master
                   allow_nullable_unique_key
                   allow_on_master
                   allow_zero_in_date
                   approve_renamed_columns
                   assume_master_host
                   assume_rbr
                   attempt_instant_ddl
                   azure
                   binlogsyncer_max_reconnect_attempts
                   check_flag
                   chunk_size
                   concurrent_rowcount
                   conf
                   critical_load
                   critical_load_hibernate_seconds
                   critical_load_interval_millis
                   cut_over
                   cut_over_exponential_backoff
                   cut_over_lock_timeout_seconds
                   database
                   debug
                   default_retries
                   discard_foreign_keys
                   dml_batch_size
                   exact_rowcount
                   exponential_backoff_max_interval
                   force_named_cut_over
                   force_named_panic
                   force_table_names
                   gcp
                   heartbeat_interval_millis
                   hooks_hint
                   hooks_hint_owner
                   hooks_hint_token
                   hooks_path
                   host
                   ignore_http_errors
                   initially_drop_ghost_table
                   initially_drop_old_table
                   initially_drop_socket_file
                   master_password
                   master_user
                   max_lag_millis
                   max_load
                   migrate_on_replica
                   mysql_timeout
                   nice_ratio
                   ok_to_drop_table
                   panic_flag_file
                   password
                   port
                   postpone_cut_over_flag_file
                   quiet
                   replica_server_id
                   serve_socket_file
                   serve_tcp_port
                   skip_foreign_key_checks
                   skip_renamed_columns
                   skip_strict_mode
                   ssl
                   ssl_allow_insecure
                   ssl_ca
                   ssl_cert
                   ssl_key
                   stack
                   switch_to_rbr
                   test_on_replica
                   test_on_replica_skip_replica_stop
                   throttle_additional_flag_file
                   throttle_control_replicas
                   throttle_flag_file
                   throttle_http
                   throttle_http_interval_millis
                   throttle_http_timeout_millis
                   throttle_query
                   timestamp_old_table
                   tungsten
                   user
                   verbose].freeze
  Config = Struct.new(*CONFIG_KEYS, keyword_init: true) do
    def merge!(other_config)
      other_config.compact.each { |k, v| self[k] = v }
      self
    end

    def with_env
      env_config = EnvParser.new(ENV).config
      compact.merge(env_config)
    end

    def compact
      to_h.compact
    end

    def as_args(context: {})
      full_context = context.merge(compact)
      with_env.map { |key, value| arg(key, value, full_context) }.compact
    end

    private

    def arg(key, value, context)
      return unless value

      hyphenated_key = key.to_s.gsub('_', '-')
      if value == true
        "--#{hyphenated_key}"
      else
        substituted_value = substitute_value(value, context)
        "--#{hyphenated_key}=#{substituted_value}"
      end
    end

    def substitute_value(value, context)
      return value unless value.is_a? String
      return value unless value =~ /<%=.*%>/

      ERB.new(value).result_with_hash(context)
    end
  end
end
