# Koshu (shell)

Task automation for shell

## Setup

Download koshu.sh to a directory and create a file named "koshufile" in the same directory.

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

## Running koshu

    ./koshu.sh <taskname>

To make running koshu easier, add an alias for koshu.sh to your shell.

    alias koshu='./koshu.sh'

Using the alias above you may now execute koshu like this:

    koshu <taskname>
