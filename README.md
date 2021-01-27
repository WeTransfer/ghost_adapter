# Ghost Adapter

A tiny, configurable ActiveRecord adapter built for running [gh-ost](https://github.com/github/gh-ost) migrations. When not running migrations, it'll stay the heck out of the way.

## Installation

First, you'll need to install `gh-ost`. You can find the latest release [here](https://github.com/github/gh-ost/releases/latest). Once you've got that installed, install the gem!

Add this line to your application's Gemfile:

```ruby
gem 'ghost_adapter'
```

And then execute:

    $ bundle install

## Usage

### Connect with ActiveRecord

Configure your ActiveRecord connection to use `ghost_mysql2` as the adapter in whichever environments you'd like to use `gh-ost`.

For a standard rails project, in `config/database.yml` set `adapter: ghost_mysql2`.

### Configure the Environment

The following environment variables are expected to be present:

- `DATABASE_NAME` => the name of your application's database
- `DATABASE_MAIN_HOST` => the host URL / IP of your main database (e.g. localhost)
- `DATABASE_READ_REPLICA_HOST` => the host URL / IP of your read replica database (for development, same as main host)
- `DATABASE_MIGRATION_USER` => database user with permissions to run migrations
- `DATABASE_MIGRATION_PASSWORD` => password for database user with permissions to run migrations

### Using the adapter

Since most database activity isn't a migration, we default to identical behavior to the Mysql2Adapter. No need to be executing a bunch of extra logic per query when you're only getting any value for migrations.

To enable the ghost adapter, simply set `GHOST_MIGRATION=1` in the environment where you're running the migration. Like this:

```
GHOST_MIGRATION=1 bundle exec rake db:migrate
```

If you want to do a dry run first (recommended), no problem! Like this:

```
GHOST_MIGRATION=1 DRY_RUN=1 bundle exec rake db:migrate
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/ghost_adapter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/wetransfer/ghost_adapter/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [Hippocratic License](https://firstdonoharm.dev/version/2/1/license.html).

## Code of Conduct

Everyone interacting in the Ghost Adapter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/wetransfer/ghost_adapter/blob/master/CODE_OF_CONDUCT.md).
