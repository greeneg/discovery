#!/usr/bin/env perl

#########################################################################################
#                                                                                       #
# Application: discovery.pl                                                             #
# Summary:     A System Discovery Tool                                                  #
# Author:      Gary L. Greene, Jr. <greeneg@yggdrasilsoft.com>                          #
# Copyright:   2011-2017 YggdrasilSoft, LLC.                                            #
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

package Discovery::Plugins::OperatingSystem;

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

use Config;
use Data::Dumper;
use POSIX;
use String::Util qw(trim);

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;
}

sub get_darwin_distribution ($self, $system) {
    my $distribution = '';
    if (-x '/usr/sbin/system_profiler') {
        # get the dump from system_profiler as XML
        chomp(my @dump = qx|/usr/sbin/system_profiler SPSoftwareDataType|);
        # we only want the system version
        foreach my $line (@dump) {
            next if $line !~ /System Version/;
            # parse this into two lines
            my (undef, $os_name) = split(':', $line);
            # we only want the non-version nor build bits
            # remove all numbers
            $os_name =~ s/\d//g;
            # remove the dots from what was the version string
            $os_name =~ s/\.//g;
            # nuke the rest of the build info
            $os_name =~ s/\(\w+\)//g;
            # strip leading whitespace
            $os_name = trim($os_name);
            $distribution = $os_name;
        }
    } else {
        # insufficient tooling, so call this darwin and move on
        $distribution = lc($system);
    }

    return $distribution;
}

sub get_linux_distribution {
    my $distribution;

    if (-f '/etc/os-release') {
        open my $os_release, '/etc/os-release';
        foreach my $l (<$os_release>) {
            if ($l =~ /^ID\=.*$/) {
                (undef, $distribution) = split('=', $l);
                chomp($distribution);
            }
        }
        close $os_release;
    }

    return $distribution;
}

sub get_distribution ($self, $system, $release, $build) {
    my $distribution = '';
    if ($system eq 'Darwin') {
        $distribution = get_darwin_distribution($self, $system);
    } elsif ($system eq 'Linux') {
        $distribution = get_linux_distribution();
    }

    return $distribution;
}

our sub runme ($self, $os) {
    my %values;

    my ($system, undef, $release, $build, undef) = POSIX::uname();

    $values{'operating_system'}->{'family'} = lc($system);
    $values{'operating_system'}->{'distribution'} = get_distribution($self, $system, $release, $build);
#    $values{'operating_system'}->{'name'} = get_name($self, $system, $release, $build);
#    $values{'operating_system'}->{'version'} = get_version();

    return %values;
}

1;
