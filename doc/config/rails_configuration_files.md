# Configuration

## Via Rails Configuration Files

ghost_adapter is set up to receive configuration via [any of the many ways to configure your rails application](https://guides.rubyonrails.org/configuring.html).

## Example

Whether in the `config/application.rb` or any of the `config/environments/<ENV>.rb` files, you can configure `ghost_adapter` like this:

```ruby
Rails.application.configure do
  ...
  config.ghost_adapter.allow_on_master = true
  config.ghost_adapter.database = 'my-lovely-database'
  config.ghost_adapter.max_lag_millis = 100
  config.ghost_adapter.nice_ratio = .99
  ...
end
```

## Other Configuration Methods

- [Via Environment Variable](./config/environment_variables.md)
- [Via Rails Configuration Files](./config/rails_configuration_files.md)
- [Via GhostAdapter.setup Method](./config/setup_method.md)
