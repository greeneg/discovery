#!/usr/bin/env perl -T
#
# Author: Gary Greene <greeneg@tolharadys.net>
# Copyright: 2017 YggdrasilSoft, LLC. All Rights Reserved
#
##########################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#    
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. 
#

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
