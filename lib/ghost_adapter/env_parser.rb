module GhostAdapter
  class EnvParser
    attr_reader :config

    def initialize(env = {})
      @config = env.map do |key, value|
        next unless ghost_key?(key)

        config_key = convert_env_key(key)

        next unless GhostAdapter::CONFIG_KEYS.include?(config_key)

        config_value = convert_env_value(value)

        [config_key, config_value]
      end.compact.to_h
    end

    private

    def ghost_key?(key)
      key.start_with?('GHOST_') && (key != 'GHOST_MIGRATE')
    end

    def convert_env_key(key)
      key.gsub('GHOST_', '').downcase.to_sym
    end

    def convert_env_value(value)
      num_val = try_to_i_env(value) || try_to_f_env(value)
      return num_val unless num_val.nil?

      bool_val = try_to_bool_env(value)
      return bool_val unless bool_val.nil?

      value
    end

    def try_to_i_env(value)
      return unless /\A[0-9]+$/ =~ value

      value.to_i
    end

    def try_to_f_env(value)
      return unless /\A[0-9]*\.[0-9]+$/ =~ value

      value.to_f
    end

    def try_to_bool_env(value)
      lowered = value.downcase
      return true if %w[yes y true t].include? lowered

      return false if %w[no n false f].include? lowered

      nil
    end
  end
end
