# Configuration

## Via GhostAdapter.setup Method

In case you're using ActiveRecord outside of rails and prefer not to set environment variables, not a problem!
There's a single static `setup` method that gives you all the same functionality as you get in rails configuration files.
This can be either called with a hash representing the configuration you want, or with a block where you get a `config` object that you can set values on.
You are free to use both the hash argument and a block, but be aware that any values set in the block will overwrite values in the hash.

## Example (with Hash)

To initialize with a hash, try something like this:

```ruby
GhostAdapter.setup({
  verbose: true,
  database: 'casper-database-development',
  ssl: true,
  host: 'localhost',
  port: 9999
})
```

(string keys are also fine, like `'verbose' => true`)

## Example (with block)

To initialize with a block, try something like this:

```ruby
GhostAdapter.setup do |config|
  config.verbose = true
  config.database = 'casper-database-development'
  config.ssl = true
  config.host = 'localhost'
  config.port = 9999
end
```

## Other Configuration Methods

- [Via Environment Variable](./environment_variables.md)
- [Via Rails Configuration Files](./rails_configuration_files.md)
- [Via GhostAdapter.setup Method](./setup_method.md)
