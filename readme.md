# Koshu (shell)

[![NPM version](https://badge.fury.io/js/koshu.png)](http://badge.fury.io/js/koshu)
[![Join the chat at https://gitter.im/kristofferahl/koshu-shell](https://badges.gitter.im/kristofferahl/koshu-shell.svg)](https://gitter.im/kristofferahl/koshu-shell?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1e82f698d11a4a2bb858ade94318ed73)](https://www.codacy.com/app/kristofferahl/koshu-shell?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=kristofferahl/koshu-shell&amp;utm_campaign=Badge_Grade)
[![CircleCI](https://circleci.com/gh/kristofferahl/koshu-shell/tree/master.svg?style=svg)](https://circleci.com/gh/kristofferahl/koshu-shell/tree/master)

The honey flavoured task automation tool

## Installation

### Prerequisites

- bash 3.2 +

### Local

Simply download koshu.sh to your project directory and execute koshu by typing `./koshu.sh`.

#### Pre-release

    curl https://raw.githubusercontent.com/kristofferahl/koshu-shell/master/src/koshu.sh > ./koshu.sh

#### Stable

    curl https://raw.githubusercontent.com/kristofferahl/koshu-shell/v0.6.2/src/koshu.sh > ./koshu.sh

To make running your "project local" koshu easier, you add an alias for koshu.sh to your shell.

    alias koshu='./koshu.sh'

### Global

You can install koshu globally using `npm install koshu -g` and execute it by typing `koshu`.

## Setup

Run koshu init to create a "koshufile" in the current directory.

## Koshufile

### Tasks

A task can be defined in two ways:

    task setup {
      echo 'Setting up...'
    }

or

    setup () {
      echo 'Setting up...'
    }

The latter is compatible with shellcheck while the first one is not.

You may also define a "default" task that is executed if no task name is passed to koshu.

    task default {
      echo 'Running default task...'
    }

### Dependencies

You can define dependencies between your tasks by using the depends_on keyword followed by the name of the task you wish to depend upon.

    task test {
      depends_on compile
    }

In the example above, the compile task will be executed before any code placed after the depends_on statement is executed. A single task will never be executed more than once.

## Executing tasks

    ./koshu.sh <taskname>

## Parameters and environment variables

### Parameters

Parameters you want set as variables can be passed to koshu by providing the `-p` or `--param` option followed by a name/value pair.

    ./koshu.sh <taskname> --param foo=bar

Default values can be set in your koshufile using variables declaration.

    foo='default value'

    task default {
      echo "$foo"
    }

### Environment variables

Parameters you want set as environment variables can be passed to koshu by providing the `-e` or `--env` option followed by a name/value pair.

    ./koshu.sh <taskname> --env FOO=bar

Default values are currently not supported for the `-e` or `--env` option.

### NOTE: Spaces

If a value includes spaces you need to quote it!

    ./koshu.sh <taskname> --param foo='some value for foo' --env BAR='some value for BAR'

## Help

For more info on using koshu, please run the help command.

    ./koshu.sh help
