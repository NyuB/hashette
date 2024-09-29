# hashette

![ci-status](https://github.com/NyuB/hashette/actions/workflows/ci.yml/badge.svg?event=push&branch=main)

File hashing utility

## Development

- run the tests: `make test`
- update the tests' expectations: `make test-promote`
- format source code: `make fmt`

## Installation

Run `make install` to build and copy `hashette` to your system. Installation folder is specified with the variable `INSTALL_ROOT` (default to `~/bin`), e.g.

`make install INSTALL_ROOT=/usr/custom/bin`
