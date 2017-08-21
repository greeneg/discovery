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

package Discovery::Config;

use strict;
use warnings;
use feature ":5.22";
# Add features to system for lexical subs and signatures
# disable all warnings for these as they are still experimental
# (likely won't change much though in the future...)
no warnings "experimental::lexical_subs";
no warnings "experimental::signatures";
no warnings "experimental::smartmatch";
use feature 'lexical_subs';
use feature 'signatures';
use feature 'switch';
use English;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Config;
use Discovery::Constants;
use Discovery::Logger;
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

our sub _initialize ($self, $config, $debug) {
    my $sub = (caller(0))[3];

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__, ": Setting up Config object" if $debug;

    %config = %{$config};
    $DEBUG = $debug;

    given ($self->get_os(\$config, $debug)) {
        when (/^darwin/) {
            $config{'platform_defaults'} = {
                'install_directory'   => '/opt/configmgr',
                'externals_directory' => '/opt/configmgr/lib/discovery.d/'
            };
            break;
        }
        when (/^linux/) {
            $config{'platform_defaults'} = {
                'install_directory'   => '/opt/configmgr',
                'externals_directory' => '/opt/configmgr/lib/discovery.d/'
            };
            break;
        }
    }
}

our sub get_os ($self, $config, $debug) {
    my $sub = (caller(0))[3];

    my $os;

    say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__, ": OPERATING SYSTEM: $Config{osname}" if $debug;
    say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__, ": OPERATING SYSTEM: $Config{archname}" if $debug;
    say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__, ": OPERATING SYSTEM VERSION: $Config{osvers}" if $debug;

    $os = $Config{osname};

    return $os;
}

1;
