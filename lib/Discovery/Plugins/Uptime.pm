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

package Discovery::Plugins::Uptime;

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

BEGIN {
    if ($OSNAME eq 'Linux' || $OSNAME eq 'Darwin') {
        use Unix::Uptime;
    } elsif ($OSNAME eq 'Win32') {
        require Win32::Uptime;
        import Win32::Uptime;
    }
}

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;   
}

my sub uptime_days ($seconds) {
    my $days = $seconds / 86400;

    return int $days;
}

my sub uptime_hours ($seconds) {
    my $hours = $seconds / 3600;

    return int $hours;
}

our sub runme ($self, $os, $format) {
    my $sub = (caller(0))[3];

    my $seconds;
    my $hours;
    my $days;
    my %uptime;

    if ($os eq "linux" || $os eq 'darwin') {
        $seconds = Unix::Uptime->uptime();
        $days = uptime_days($seconds);
        $hours = uptime_hours($seconds);
        %uptime = (
            'hours'   => $hours,
            'days'    => $days,
            'seconds' => $seconds,
        );
    } elsif ($os eq "win32") {
        my $msecs = Win32::Uptime->uptime();

        # process into seconds
        $seconds = $msecs / 1000;
        $days = uptime_days($seconds);
        $hours = uptime_hours($seconds);
        %uptime = (
            'hours'   => $hours,
            'days'    => $days,
            'seconds' => $seconds,
        );
    }

    if ($format eq "plain") {
        say "system_uptime => { \"seconds\" => $seconds, \"hours\" => $hours, \"days\" => $days, \"uptime\" => $days days }";
        say "uptime => $days days";
        say "uptime_days => $days";
        say "uptime_hours => $hours";
        say "uptime_seconds => $seconds";        
    } elsif ($format eq "json") {
        
    } elsif ($format eq "perleval") {
        
    }
}

our sub provides {
    say "system_uptime";
    say "uptime";
    say "uptime_days";
    say "uptime_hours";
    say "uptime_seconds";
}

1;
