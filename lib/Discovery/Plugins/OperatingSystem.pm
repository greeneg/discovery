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
use feature 'switch';
use English;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use boolean;
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
                $distribution =~ s/"//g;
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

sub get_darwin_os_name ($self, $system) {
    my $sub = (caller(0))[3];
    my $os_name = '';

    if (-x '/usr/sbin/system_profiler') {
        # get the dump from system_profiler as XML
        chomp(my @dump = qx|/usr/sbin/system_profiler SPSoftwareDataType|);
        # we only want the system version
        foreach my $line (@dump) {
            next if $line !~ /System Version/;
            # parse this into two lines
            (undef, $os_name) = split(':', $line);
            # we only want the non-version nor build bits
            # remove all numbers
            $os_name =~ s/\d//g;
            # remove the dots from what was the version string
            $os_name =~ s/\.//g;
            # nuke the rest of the build info
            $os_name =~ s/\(\w+\)//g;
            # strip leading whitespace
            $os_name = trim($os_name);
        }
        # now, let's get the OS' series number
        my $series = '';
        my $version = '';
        if (-x '/usr/bin/sw_vers') {
            chomp($version = qx|/usr/bin/sw_vers -productVersion|);
            # now split so we get the series
            my ($maj, $min, undef) = split(/\./, $version);
            # now, reconstruct the series
            $series = "$maj.$min";
        }
        my $code_name = '';
        if ($series eq '10.12') {
            $code_name = 'Sierra';
        } elsif ($series eq '10.13') {
            $code_name = 'High Sierra';
        } elsif ($series eq '10.14') {
            $code_name = 'Mojave';
        } elsif ($series eq '10.15') {
            $code_name = 'Catalina';
        }
        # assemble the system name
        $os_name = "$os_name $code_name $version";
    } else {
        # insufficient tooling, so call this darwin and move on
        $os_name = $system;
    }

    return $os_name;
}

sub get_linux_os_name {
    my $os_name;

    if (-f '/etc/os-release') {
        open my $os_release, '/etc/os-release';
        foreach my $l (<$os_release>) {
            if ($l =~ /^PRETTY_NAME\=.*$/) {
                (undef, $os_name) = split('=', $l);
                chomp($os_name);
                # strip quotes
                $os_name =~ s/"//g;
            }
        }
        close $os_release;
    }

    return $os_name;
}

sub get_name ($self, $system) {
    my $os_name = '';

    if ($system eq 'Darwin') {
        $os_name = get_darwin_os_name($self, $system);
    } elsif ($system eq 'Linux') {
        $os_name = get_linux_os_name();
    }

    return $os_name;
}

sub get_darwin_version ($self, $version) {
    my $os_version = '';

    my $_version = '';
    if (-x '/usr/bin/sw_vers') {
        chomp($_version = qx|/usr/bin/sw_vers -productVersion|);
        $os_version = $_version;
    } else {
        # must be running on an Open Darwin release, which is versioned after
        # the Kernel
        $os_version = $version;
    }

    return $os_version;
}

sub get_linux_version {
    my $os_version;

    if (-f '/etc/os-release') {
        open my $os_release, '/etc/os-release';
        foreach my $l (<$os_release>) {
            if ($l =~ /^VERSION_ID\=.*$/) {
                (undef, $os_version) = split('=', $l);
                chomp($os_version);
                $os_version =~ s/"//g;
            }
        }
        close $os_release;
    }

    return $os_version;
}

sub get_version ($self, $system, $version) {
    my $os_version = '';

    if ($system eq 'Darwin') {
        $os_version = get_darwin_version($self, $version);
    } elsif ($system eq 'Linux') {
        $os_version = get_linux_version();
    }

    return $os_version;
}

sub get_xenu_build ($self, $build) {
    my $kernel_build = '';

    my $_build;
    if (-x '/usr/bin/sw_vers') {
        chomp($_build = qx|/usr/bin/sw_vers -buildVersion|);
        $kernel_build = $_build;
    } else {
        # use the long build string
        $kernel_build = $build;
    }

    return $kernel_build;
}

sub get_build ($self, $system, $build) {
    my $kernel_build = '';

    if ($system eq 'Darwin') {
        $kernel_build = get_xenu_build($self, $build);
    } elsif ($system eq 'Linux') {
        $kernel_build = $build;
    }

    return $kernel_build;
}

our sub runme ($self, $os, $debug) {
    my %values;

    my ($system, undef, $release, $build, undef) = POSIX::uname();

    $values{'OperatingSystem'}->{'family'} = lc($system);
    $values{'OperatingSystem'}->{'distribution'} = get_distribution($self, $system, $release, $build);
    $values{'OperatingSystem'}->{'name'} = get_name($self, $system);
    $values{'OperatingSystem'}->{'version'} = get_version($self, $system, $release);
    $values{'OperatingSystem'}->{'kernel_version'} = $release;
    $values{'OperatingSystem'}->{'kernel_build'} = get_build($self, $system, $build);

    return %values;
}

true;
