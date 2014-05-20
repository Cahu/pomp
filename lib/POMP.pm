package POMP;

use strict;
use threads;
use threads::shared;
use Thread::Queue;

our $VERSION = 0.1;

our @POMP_THREADS;
our @POMP_IN_QUEUES;
our @POMP_OUT_QUEUES;
our $POMP_NUM_THREADS = 4;

my $barrier :shared = 0;

use constant {
	CALL => 1,    # call a sub with given parameters
	EXIT => 2,    # exit loop and terminate
};


# consumer function
sub POMP_CONSUMER {
	my $self = threads->self();
	my ($in_queue) = @_;

	while (my $instr = $in_queue->dequeue()) {
		my ($code, $sub, @sub_args) = @$instr;

		if ($code == CALL) {
			# It's not possible to pass code refs to queues. We have to
			# disable strict ref to use the name (string) of the sub instead.
			no strict 'refs';
			$sub->(@sub_args);
		}

		elsif ($code == EXIT) {
			last;
		}
	}
}

sub GET_TID {
	return threads->tid();
}

sub ENQUEUE {
	my ($serialized) = @_;
	my $queue = $POMP_OUT_QUEUES[GET_TID()];
	$queue->enqueue($serialized);
}

sub GET_SHARE {
	my @list = @_;

	my $start;
	my $end;

	my $tid = GET_TID();

	if ($tid >= @list) {
		return ();
	}

	if ($POMP_NUM_THREADS >= @list) {
		$start = $tid;
		$end = $tid;
	}

	else {
		$start = int ((  $tid) * @list / $POMP_NUM_THREADS    );
		$end   = int ((1+$tid) * @list / $POMP_NUM_THREADS - 1);
	}

	return @list[$start .. $end];
}


sub BARRIER {
	lock($barrier);
	$barrier++;

	if ($barrier == $POMP_NUM_THREADS) {
		$barrier = 0;
		cond_broadcast($barrier);
	} else {
		cond_wait($barrier);
	}
}


INIT {
	# IN_QUEUES to pass opcodes and params
	# main thread doesn't need an IN_QUEUE
	@POMP_IN_QUEUES  = map { Thread::Queue->new(); } (1..$POMP_NUM_THREADS-1);

	# OUT_QUEUES to return values
	# main thread needs an OUT_QUEUE for reductions
	@POMP_OUT_QUEUES = map { Thread::Queue->new(); } (1..$POMP_NUM_THREADS  );

	# Spawn threads and give them queues
	@POMP_THREADS = map {
		threads->create(
			\&POMP_CONSUMER,
			$POMP_IN_QUEUES[$_],
		);
	} (0..$POMP_NUM_THREADS-2);
}


END {
	# Clean up
	$_->enqueue([EXIT]) for (@POMP_IN_QUEUES);
	$_->join() for (@POMP_THREADS);
}

1;
