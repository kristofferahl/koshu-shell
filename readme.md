# Koshu (shell)

[![Join the chat at https://gitter.im/kristofferahl/koshu-shell](https://badges.gitter.im/kristofferahl/koshu-shell.svg)](https://gitter.im/kristofferahl/koshu-shell?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

The honey flavoured task automation tool

## Installation

### Local

Simply download koshu.sh to your project directory and execute koshu by typing `./koshu.sh`. To make running your "project local" koshu easier, you add an alias for koshu.sh to your shell.

    alias koshu='./koshu.sh'

### Global

You can install koshu globally using `npm install koshu -g` and execute it by typing `koshu`.

## Setup

Run koshu init to create a "koshufile" in the current directory.

## Koshufile

### Tasks

Use the following syntax in your koshufile to define a task.

    task setup {
      echo 'Setting up...'
    }

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

## Help

For more info on using koshu, please run the help command.

    ./koshu.sh help
