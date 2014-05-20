% POMP development notes
%
%

# What this module actualy does

This software does two things. First, it installs a module that spawns threads and
provides some utility functions for parallel tasks managements. Second it
provides a compiler that takes a perl script annotated with `#pomp_*` commands
and transform the code to make the annotated code run in parallel.


# Threads

A modified script produced by the compiler has an `use POMP.pm` statement. This
module spawns a collection of worker threads which execute an infinite loop that
pulls tasks from a queue. All threads have their own input queue (where they
pull tasks from) and their own output queue (where they write results).

Messages pulled from the queue are array refs that contain an opcode followed by
arguments. Example of opcodes are:

* `CALL`: call a sub. Arguments are the name of the subroutine to call followed
  by the parameters to pass to it.
* `EXIT`: exit the consumer loop and terminate.


# Generated subs

All parallelized code is handled by creating a sub which can be passed **by
name** to worker threads.

The generated subs (which contain the code to be run in parallel) contain a
synchronization statement (with a barrier) before exiting.

## Calling

### Opcode

The opcode to be enqueued is `CALL`. Arguments are the name of the subroutine to
call followed by the parameters to pass to it.

### Sub name

The generated sub name is passed with something that looks like
`__PACKAGE__ . '::generated_unique_sub_name'`.

### Private variables

Nothing is done at the call stage for private vars.

### Firstprivate variables


### Reductions

After the call, reductions are handled by inserting the code provided by the
user which should take a string as a parameter. This string is a piece of code
that will generate the list of arguments when the program is actually run. It
looks like this:

`map { thaw($_->dequeue) } @POMP::POMP_OUT_QUEUES`

This will pull (frozen) return values produced by threads. User's code can do
whatever he wants with them in the code he supplied.

### Shared variables

Before the call, cloned versions of shared variables are created (with
`shared_clone()`). These are passed as argument to the worker thread which in
turn will pass them to the parallel sub.

After the call, the value contained in the clone is copied back into the
original variable.

### For loops

### Arguments order

The order is : firstprivate variables, shared variables, for loop interation
list.

## Variables

### Private variables

Variables declared private are handled by declaring a local version within the
generated sub. This is simply done by inserting a `my $private_var;`
statement in the corresponding sub.

### Firstprivate variables

Firstprivate variables are handled by declaring a local version withing the
generated sub and by initializing it with a `thaw(shift)`. For this to work, a
frozen version of the variable is passed as an argument to the generated sub.

### Reductions

### Shared variables

Shared variables are handled through their shared clone. Since the clone is
actualy a reference, all occurences in the parallel code are replaced with a
dereference instruction.

```
ORIGINAL                 REPLACEMENT

$variable         --->   ${ $clone }

$variable[$idx]   --->   $clone->[$idx]
@variable         --->   @{ $clone }

$variable{$key}   --->   $clone->{$key}
%variable         --->   %{ $clone }
```

## For loops
