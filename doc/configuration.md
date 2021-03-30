# Configuration

To get a list of possible configuration options, simply run `gh-ost --help` locally and convert the hyphenated args to be underscored. There are a few args that are not accepted:

## Excluded Arguments

- `alter` => this is required and will be set automatically based on the output of your migration
- `table` => same story as `alter`
- `help` => this wouldn't be useful
- `version` => also wouldn't be useful
- `ask-pass` => at the moment we only support the `password` flag (so we don't have to deal with accepting input mid-migration)

## Methods of Configuration

- [Via Environment Variable](./config/environment_variables.md)
- [Via Rails Configuration Files](./config/rails_configuration_files.md)
- [Via GhostAdapter.setup Method](./config/setup_method.md)

## Templating

You can use ERB templates to get dynamic values for your configuration. Read more here: [Templating](./config/templating.md)

## Nice to Know

- For boolean args (that do not require a value in the command line), set them as `true`/`false` and they will be either included or excluded accordingly.
- There is not (yet!) any type checking on the arguments, so it's up to you to know what values should be expected (run `gh-ost --help` for assistance)
