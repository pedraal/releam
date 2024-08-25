# releam

[![Package Version](https://img.shields.io/hexpm/v/releam)](https://hex.pm/packages/releam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/releam/)

Releam is an opinionated gleam package release CLI tool and also a set of utilities for parsing conventional commits.
It is based on the semver and conventional commit specs. Invalid conventional commits will be ignored by this tool.

It is highly inspired by [unjs/changelogen](https://github.com/unjs/changelogen), shoutout to the unjs team for the amazing work in JS land ! You can expect more features comming from this tool in the future.

## Install
```sh
gleam add --dev releam
```

## Usage
Once you are ready to create a new release from your main git branch, run the following :
```sh
gleam run -m releam
```
It will :
- parse the new commits since the last git tag
- bump your package version
- generate a changelog based on your conventional commits messages
- prepend the changelog to your `CHANGELOG.md` (if it's missing it will create it)
- create a release commit and a new tag
- if your repository host is supported, it will print a link to your terminal to create a new release (currently only github is supported)

If you have specific requirements, this package exposes all its internal function for you to build your custom release script.

## Configuration
You can configure automatic git push when running releam by adding this to your `gleam.toml` :
```toml
[releam]
auto_push = true
```
By default, auto push is disabled.

## Documentation
Further documentation can be found at <https://hexdocs.pm/releam>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
