# Configuration

## Via Environment Variables

Configuration with environment variables is very simple. All variable names should be in the format `GHOST_<capitalized config option>`. For example: `GHOST_VERBOSE`.

We automatically (attempt to) parse arguments to integers, floats, and booleans (in that order.)
For boolean values, you can use any of `y`, `yes`, `t`, `true` to represent true. You can use `n`, `no`, `f`, `false` to represent false.
If we are unable to convert the value to any of those types, we the value is kept as a string.

## Example

```shell
GHOST_VERBOSE=y \
GHOST_HOST=localhost \
GHOST_NICE_RATIO=0.71 \
GHOST_PORT=1599 \
ruby <your command>
```

## Other Configuration Methods

- [Via Environment Variable](./environment_variables.md)
- [Via Rails Configuration Files](./rails_configuration_files.md)
- [Via GhostAdapter.setup Method](./setup_method.md)
