package Discovery::Util;

use v5.22;
use Data::Dumper;

my $VERSION = 0.1;

# private variables
my %config;
my $DEBUG;

sub new {
    my $class = shift;
    my $config = shift;
    my $DEBUG = shift;

    my $self = {};
    bless $self, $class;

    # now set the local variables for the class
    $self->_initialize($config, $DEBUG);

    return $self;
}


sub _initialize {
    my $sub = (caller(0))[3];

    print STDERR __PACKAGE__, ': ', "$sub: ", __LINE__, ": Setting up Util object\n";

    %config = %{$_[1]};
    $DEBUG = $_[2];
}

sub discovery_loop {
}

1;
