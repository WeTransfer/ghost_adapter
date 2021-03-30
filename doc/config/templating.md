# Configuration

## Templating

No matter which configuration method you use, you can use ERB templating to fill in dynamic values. For example, you may want to use the table name, or the timestamp in the path for the throttle flag file. Well, you can do that!

You can use any configuration key as a template variable. Along with the configuration keys, we have added a few additional "magic helpers":

- `pid`: the current process ID
- `timestamp`: current seconds since epoch (as integer)
- `unique_id`: random UUID
- `table`: the table being migrated
- `database`: the database the migration is being run against

### Example

Setting the configuration using some "magic helpers":

```ruby
config.ghost_adapter.throttle_flag_file = '/tmp/<%= table %>/<%= pid %>-<%= timestamp %>.throttle'
```

will result in a value like `/tmp/things/29882-1617119851.throttle`

---

Setting the configuration using your other config:

```ruby
config.ghost_adapter.user = 'great_user'
config.ghost_adapter.panic_flag_file = '/tmp/<%= user %>.panic'
```

will result in a value like `/tmp/great_user.panic`

## Configuration Methods

- [Via Environment Variable](./environment_variables.md)
- [Via Rails Configuration Files](./rails_configuration_files.md)
- [Via GhostAdapter.setup Method](./setup_method.md)
