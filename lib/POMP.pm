package POMP;

use strict;
use threads;
use Thread::Queue;

our $VERSION = 0.1;

our @POMP_THREADS;
our @POMP_IN_QUEUES;
our @POMP_OUT_QUEUES;
our $POMP_NUM_THREADS = 4;

use constant {
	CALL => 1,    # call a sub with given parameters
	EXIT => 2,    # exit loop and terminate
};


# consumer function
sub POMP_CONSUMER {
	my $self = threads->self();
	my ($in_queue, $out_queue) = @_;

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

		$out_queue->enqueue(1); # Signal done
	}
}

sub GET_TID {
	return threads->tid();
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


INIT {
	# Create queues and spawn threads
	@POMP_IN_QUEUES  = map { Thread::Queue->new(); } (1..$POMP_NUM_THREADS-1);
	@POMP_OUT_QUEUES = map { Thread::Queue->new(); } (1..$POMP_NUM_THREADS-1);
	@POMP_THREADS = map {
		threads->create(
			\&POMP_CONSUMER,
			$POMP_IN_QUEUES[$_],
			$POMP_OUT_QUEUES[$_],
		);
	} (0..$POMP_NUM_THREADS-2);
}


END {
	# Clean up
	$_->enqueue([EXIT]) for (@POMP_IN_QUEUES);
	$_->join() for (@POMP_THREADS);
}

1;
