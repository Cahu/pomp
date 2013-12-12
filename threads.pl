#use strict;
#use warnings;

use threads;
use Thread::Queue;

my @POMP_QUEUES;
my @POMP_THREADS;

use constant {
	CALL => 1,
	EXIT => 2,
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
			{
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
	@POMP_QUEUES  = map { Thread::Queue->new(); } (0..3);
	@POMP_THREADS = map {
		threads->create(\&POMP_CONSUMER, $POMP_QUEUES[$_]);
	} (0..3);
}


END {
	# clean up
	$_->enqueue([EXIT, undef]) for (@POMP_QUEUES);
	$_->join() for (@POMP_THREADS);
}


sub foo { print "Hello World!\n"; }
$_->enqueue([CALL, "foo"]) for (@POMP_QUEUES);
