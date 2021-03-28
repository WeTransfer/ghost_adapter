# CHANGELOG

## 0.1.4

- Fix bug caused by missing `require 'open3'` that occurs for some ruby versions

## 0.1.3

- Fix bug [#26](https://github.com/WeTransfer/ghost_adapter/issues/26) causing environment configuration to be overwritten by some other configuration methods.

## 0.1.2

- Fix bug [#28](https://github.com/WeTransfer/ghost_adapter/issues/28) that resulted in add_index and remove_index calls to not run through `gh-ost`
