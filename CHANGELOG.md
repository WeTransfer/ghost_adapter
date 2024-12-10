# CHANGELOG

## 0.7.0
- Chore: add short docs for how to release the gem ([#76](https://github.com/WeTransfer/ghost_adapter/pull/76))
- Update activerecord requirement from >= 5, <= 7.2 to >= 5, <= 8.1 ([#78](https://github.com/WeTransfer/ghost_adapter/pull/78))
- Add support for gh-ost v1.1.6 command line flags and drop deprecated flag ([#79](https://github.com/WeTransfer/ghost_adapter/pull/79))

## 0.6.0
- Update activerecord requirement from >= 5, <= 7.1 to >= 5, <= 7.2 ([#75](https://github.com/WeTransfer/ghost_adapter/pull/75))

## 0.5.0
- Add support for optional async argument ([#72](https://github.com/WeTransfer/ghost_adapter/pull/72))

## 0.4.2
- Allow backticks in gh-ost query ([#71](https://github.com/WeTransfer/ghost_adapter/pull/71))

## 0.4.1
- Add support for ActiveRecord 7.0.1 ([#69](https://github.com/WeTransfer/ghost_adapter/pull/69))

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
