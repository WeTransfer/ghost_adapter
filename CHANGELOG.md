# CHANGELOG

## 0.4.0
- Add support for ActiveRecord 7 ([#67](https://github.com/WeTransfer/ghost_adapter/pull/67))

## 0.3.0
- Fix compatibility for ActiveRecord 6.1 ([#61](https://github.com/WeTransfer/ghost_adapter/pull/61))

## 0.2.3
- Add comma to allowed characters when cleaning SQL queries ([#52](https://github.com/WeTransfer/ghost_adapter/pull/52))

## 0.2.2

- Bump rexml from 3.2.4 to 3.2.5 (security fix) ([#35](https://github.com/WeTransfer/ghost_adapter/pull/35))
- Add azure configuration option now available with gh-ost v1.1.1 ([#36](https://github.com/WeTransfer/ghost_adapter/pull/36))

## 0.2.1

- Fix bug caused by missing `require 'ghost_adapter'` for non-rails apps ([#34](https://github.com/WeTransfer/ghost_adapter/pull/34))

## 0.2.0

- Add templating to configuration values. See [the docs](./docs/config/templating.md) for more info on how to use this feature.

## 0.1.4

- Fix bug caused by missing `require 'open3'` that occurs for some ruby versions

## 0.1.3

- Fix bug [#26](https://github.com/WeTransfer/ghost_adapter/issues/26) causing environment configuration to be overwritten by some other configuration methods.

## 0.1.2

- Fix bug [#28](https://github.com/WeTransfer/ghost_adapter/issues/28) that resulted in add_index and remove_index calls to not run through `gh-ost`
