#!/usr/bin/env perl

#########################################################################################
#                                                                                       #
# Application: discovery.pl                                                             #
# Summary:     A System Discovery Tool                                                  #
# Author:      Gary L. Greene, Jr. <greeneg@yggdrasilsoft.com>                          #
# Copyright:   2011-2019 YggdrasilSoft, LLC.                                            #
# License:     Apache Public License, v2                                                #
#                                                                                       #
#=======================================================================================#
#                                                                                       #
# Licensed under the Apache License, Version 2.0 (the "License");                       #
# you may not use this file except in compliance with the License.                      #
# You may obtain a copy of the License at                                               #
#                                                                                       #
#     http://www.apache.org/licenses/LICENSE-2.0                                        #
#                                                                                       #
# Unless required by applicable law or agreed to in writing, software                   #
# distributed under the License is distributed on an "AS IS" BASIS,                     #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.              #
# See the License for the specific language governing permissions and                   #
# limitations under the License.                                                        #
#                                                                                       #
#########################################################################################

package Discovery::Plugins::HostType;

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

use FindBin;
use lib "$FindBin::Bin/../lib";

use boolean;

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;   
}

my sub use_virt_what ($self) {
    # see if virt-what is available
    my $is_available = false;
    my $path         = undef;
    if (-x '/usr/sbin/virt-what') {
        $is_available = true;
        $path         = '/usr/sbin/virt-what';
    } elsif (-x '/usr/local/sbin/virt-what') {
        $is_available = true;
        $path         = '/usr/local/sbin/virt-what';
    }

    return ($is_available, $path);
}

our sub runme ($self, $os, $debug) {
    my %values;

    my $host_type = 'virtual';
    my ($is_available, $path) = use_virt_what($self);
    if (boolean($is_available)->isTrue) {
        my @output = qx|$path|;
        if (! defined $output[0]) {
            $host_type = 'physical';
        }
    }

    $values{'HostType'}->{'type'} = $host_type;

    return %values;
}

true;
