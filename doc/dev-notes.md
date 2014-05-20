% POMP development notes
%
%

# What this actualy does

This software does two things. First, it installs a module that spawns threads and
provides some utility functions for parallel tasks managements. Second it
provides a compiler that takes a perl script annotated with `#pomp_*` commands
and transform the code to make the annotated code run in parallel.


# Threads

A modified script produced by the compiler has an `use POMP` statement. This
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

There are multiple things that need to be handled before **and** after calling a
generated sub.

The opcode to be enqueued is `CALL`. Arguments are the name of the subroutine to
call followed by the parameters to pass to it.

### Sub name

The generated sub name is passed with something that looks like
`__PACKAGE__ . '::generated_unique_sub_name'`.

### Private variables

Nothing is done at the calling stage for private vars.

### Firstprivate variables

Firstprivate vars are serialized and passed as argument.

### Reductions

After the call, reductions are handled by inserting the code provided by the
user which should take a string as a parameter. This string is a piece of code
that will generate the list of arguments when the program is actually run. It
looks like this:

```map { thaw($_->dequeue) } @POMP::POMP_OUT_QUEUES```

This will pull (frozen) return values produced by threads. Users' code can do
whatever they wants with them in the code they supplied.

### Shared variables

Before the call, cloned versions of shared variables are created (with
```shared_clone()```). These are passed as argument to the worker thread which in
turn will pass them to the parallel sub.

After the call, the value contained in the clone is copied back into the
original variable.

### For loops

### Arguments order

The order of the arguments : firstprivate variables, shared variables, for loop interation
list.


### Example of a call

```perl
#pomp_for shared(@A_square) firstprivate(@A)
for my $i (0 .. 3) {
	for my $j (0 .. 3) {
		for my $k (0 .. 3) {
			$A_square[$i][$j] += $A[$i][$k] * $A[$k][$j];
		}
	}
}
```

The code above will be transformed into:

```perl
my $pomp_for1_A_square = shared_clone(\@A_square);
my $pomp_for1_A = freeze(\@A);

$_->enqueue([
	POMP::CALL,
	__PACKAGE__ . "::pomp_for1",
	$pomp_for1_A,$pomp_for1_A_square,(0 .. 3)
]) for (@POMP::POMP_IN_QUEUES);

pomp_for1($pomp_for1_A,$pomp_for1_A_square,(0 .. 3));

@A_square = @{ $pomp_for1_A_square };
```



## Sub body

### Private variables

Variables declared private are handled by declaring a local version within the
generated sub. This is simply done by inserting a ```my $private_var;```
statement in the corresponding sub.

### Firstprivate variables

Firstprivate variables are handled by declaring a local version within the
generated sub and by initializing it with a `thaw(shift)`. For this to work, a
frozen version of the variable is passed as an argument to the generated sub.

### Reductions

Accumulator variables used in reductions are lexical variables initialized with
the init value from the reduction's definition. Their value at the end of the
sub is pushed in a thread's ```POMP_OUT_QUEUE```.

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

## Declaring reductions

```perl
$POMP_reductions{'+'} = POMP::Reduction->new(
	0, sub {
		my ($accumulator, $refs_list) = @_;
		return "$accumulator += \$\$_ for ($refs_list);";
	}
);
```

```perl
$POMP_reductions{'push'} = POMP::Reduction->new(
	'()', sub {
		my ($accumulator, $refs_list) = @_;
		return "push $accumulator, map { \@\$_ } $refs_list;";
	}
);
```

