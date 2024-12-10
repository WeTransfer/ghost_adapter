# Ghost Adapter

![ghost](./doc/images/ghost.png)

[![Gem](https://img.shields.io/gem/v/ghost_adapter)](https://rubygems.org/gems/ghost_adapter)
![GitHub Actions Workflow](https://github.com/WeTransfer/ghost_adapter/actions/workflows/tests.yml/badge.svg)
[![Hippocratic License](https://img.shields.io/badge/license-Hippocratic-green)](https://github.com/WeTransfer/ghost_adapter/blob/main/LICENSE.md)
[![gh-ost version](https://img.shields.io/badge/gh--ost%20version-1.1.1-blue)](https://github.com/github/gh-ost/releases/latest)

A tiny, _very configurable_ ActiveRecord adapter built for running [gh-ost](https://github.com/github/gh-ost) migrations. When not running migrations, it'll stay the heck out of the way.

## Installation

First, you'll need to install `gh-ost`. You can find the latest release [here](https://github.com/github/gh-ost/releases/latest). You can check the allowed version range in [the version checker](./lib/ghost_adapter/version_checker.rb#L13) (current range: [>= 1.1.0, < 2]). Once you've got that installed, install the gem!

Add this line to your application's Gemfile:

```ruby
gem 'ghost_adapter'
```

And then execute:

    $ bundle install

## Usage

### Connect with ActiveRecord

Configure your ActiveRecord connection to use `mysql2_ghost` as the adapter in whichever environments you'd like to use `gh-ost`.

For a standard rails project, in `config/database.yml` set `adapter: mysql2_ghost`.

For usage with `DATABASE_URL`, only a _very tiny_ modification is necessary. The URL should be like: `mysql2-ghost://` (notice the `-` instead of `_`). This is because the scheme of a URI must be either alphanumeric or one of [`-`, `.`, `+`] ([more details](https://tools.ietf.org/html/rfc3986#section-3.1))

### Configuration

You can configure `ghost_adapter` with (nearly) all of the arguments allowed `gh-ost` in the command line. The arguments are up to date as of `gh-ost` version 1.1.0.

Read more about configuration methods in [the docs](./doc/configuration.md).

### Running Migrations

Since most database activity isn't a migration, we default to just using the `Mysql2Adapter`. No need to be executing a bunch of extra logic per query when you're only getting any value for migrations.

To enable the ghost adapter, you have two options. First (recommended) is to use the provided rails generator:

```shell
rails g ghost_adapter:install
```

This does everything you need. All migrations will run through gh-ost and otherwise the adapter will be ignored.

Alternatively, you can enable (or disable) gh-ost migrations with an environment variable.

```shell
GHOST_MIGRATE=1 rake db:...
```

If you have used the rails generator, you can set the variable to a falsey value and it will override the behavior not to use gh-ost.

- "truthy" values: `[1, t, true, y, yes]`
- "falsey" values: `[0, f, false, n, no]`

### Running tests

To run the tests for all versions, run this script:

```shell
bin/test_all_versions
```

Make sure to use the appropriate Ruby version! ActiveRecord <6.0 is not compatible with Ruby 3, so specs for those versions will only run successfully in a Ruby 2 environment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wetransfer/ghost_adapter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](./CODE_OF_CONDUCT.md).
Please add your name to the [CONTRIBUTORS.md](./CONTRIBUTORS.md)

## Releasing

### Updating version

Before releasing, make sure the version is updated appropriately. This can be done with:

```shell
bundle exec bump [major|minor|patch]
```

You should (at least roughly) follow [semver rules](https://semver.org/) for version updates.

### Publishing

Upon each version update, the new gem should be published to rubygems.org. This can be done with:

```shell
bundle exec rake release
```

This will ask you to authenticate to rubygems.org. If you have need credentials, please reach out to one of the [contributors](./CONTRIBUTORS.md)

## License

The gem is available as open source under the terms of the [Hippocratic License](https://firstdonoharm.dev/version/2/1/license.html).

## Code of Conduct

Everyone interacting in the Ghost Adapter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](./CODE_OF_CONDUCT.md).

---

Illustration by <a href="undefined">Icons 8</a> from <a href="https://icons8.com/">Icons8</a>
