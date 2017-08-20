package Discovery::Util;

use strict;
use warnings;
use feature ":5.22";
# Add features to system for lexical subs and signatures
# disable all warnings for these as they are still experimental
# (likely won't change much though in the future...)
no warnings "experimental::lexical_subs";
no warnings "experimental::signatures";
use feature 'lexical_subs';
use feature 'signatures';
use English;
use utf8;

use Data::Dumper;

my $VERSION = 0.1;

# private variables
my %config;
my $DEBUG;

sub new ($class, $config, $DEBUG) {
    my $self = {};
    bless $self, $class;

    # now set the local variables for the class
    $self->_initialize($config, $DEBUG);

    return $self;
}

sub _initialize ($self, $config, $debug) {
    my $sub = (caller(0))[3];

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__, ": Setting up Util object" if $debug;

    %config = %{$config};
    $DEBUG = $debug;
}

sub discovery_loop {
}

1;
