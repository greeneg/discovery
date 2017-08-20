package Discovery::Logger;

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

use POSIX;
use Net::Domain qw(hostname);

my %config;
my $DEBUG;

sub new ($class, $config, $DEBUG) {
    my $self = {};
    bless $self, $class;

    # now set the local variables for the class
    $self->_initialize($config, $DEBUG);

    return $self;
}

our sub _initialize ($self, $config, $debug) {
    my $sub = (caller(0))[3];

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__, ": Setting up Logger object" if $debug;

    %config = %{$config};
    $DEBUG = $debug;
}

our sub logger ($self, $appname, $log, @msg) {
    my $ltime = strftime("%b %d %H:%M:%S", localtime(time));
    my $hname = hostname;

    say $log "$ltime: $hname $appname: @msg";
}


our sub debug_logger ($self, $appname, $debug_log, @msg) {
    my $ltime = strftime("%b %d %H:%M:%S", localtime(time));
    my $hname = hostname;

    say $debug_log "$ltime: $hname $appname: @msg";
}

our sub print_and_log ($self, $appname, $debug_log, @msg) {
    $self->debug_logger($appname, $debug_log, @msg);
    say STDOUT "@msg";
}

1;
