package POMP;

use threads;
use Thread::Queue;

our @POMP_QUEUES;
our @POMP_THREADS;

use constant {
	CALL => 1,    # call a sub with given parameters
	EXIT => 2,    # exit loop and terminate
};


# consumer function
sub POMP_CONSUMER {
	my $queue = shift;
	my $self  = threads->self();
	print "Thread " . $self->tid() . " started.\n";

	while (my $instr = $queue->dequeue()) {
		my ($code, @args) = @$instr;

		if ($code == CALL) {
			print "Thread " . $self->tid() . " runs a job.\n";
			my ($sub, @sub_args) = @args;

			{	# It's not possible to pass code refs to queues. We have to
				# disable strict ref to use the name (string) of the sub instead.
				no strict 'refs';
				$sub->(@sub_args);
			}
		}

		elsif ($code == EXIT) {
			last;
		}
	}

	print "Thread " . $self->tid() . " stoped.\n";
}


INIT {
	# Create queues and spawn threads
	@POMP_QUEUES  = map { Thread::Queue->new(); } (0..3);
	@POMP_THREADS = map {
		threads->create(\&POMP_CONSUMER, $POMP_QUEUES[$_]);
	} (0..3);
}


END {
	# Clean up
	$_->enqueue([EXIT, undef]) for (@POMP_QUEUES);
	$_->join() for (@POMP_THREADS);
}

1;
