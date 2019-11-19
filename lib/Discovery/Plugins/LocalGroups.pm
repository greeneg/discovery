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

package Discovery::Plugins::LocalGroups;

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
use Data::Dumper;
use File::Slurp;
use List::MoreUtils qw(any);
use Mac::PropertyList qw(:all);

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;   
}

my sub remove_dot_files ($self, @files) {
    my @_files;

    foreach my $file (@files) {
        next if $file eq '.' or $file eq '..';
        push @_files, $file;
    }

    return @_files;
}

my sub get_plist_list ($self) {
    opendir my $pldir, '/var/db/dslocal/nodes/Default/groups' or
      die "Cannot open directory: $OS_ERROR\n";
    my @files = readdir $pldir;
    closedir $pldir;

    @files = remove_dot_files($self, @files);

    return @files;
}

my sub get_group_names ($self) {
    my @accounts;

    my @lines = read_file('/etc/group');
    foreach my $record (@lines) {
        push(@accounts, substr($record, 0, index($record, ':')));
    }

    return @accounts;
}

my sub get_local_groups ($self, $os) {
    my %values;
    my @files = ();
    if ($os eq 'darwin') {
        @files = get_plist_list($self);
        foreach my $file (@files) {
            my $record = parse_plist_file("/var/db/dslocal/nodes/Default/groups/$file") or
              die "Cannot read file $file: $OS_ERROR";
            my $grp_name = $record->{'name'}->[0]->value;
            $values{'LocalGroups'}->{$grp_name}->{'gid'} = $record->{'gid'}->[0]->value;
            if (exists $record->{'users'}) {
                $values{'LocalGroups'}->{$grp_name}->{'members'} = $record->{'users'}->values;
            }
        }
    } elsif ($os eq 'linux') {
        my @groups = get_group_names($self);
        my ($name, $gid, $members);
        while (($name, undef, $gid, $members) = getgrent()) {
            next if ! any {$_ eq $name} @groups;
            $values{'LocalUsers'}->{$name}->{'gid'} = $gid;
            my @members = split(/ /, $members);
            $values{'LocalUsers'}->{$name}->{'members'} = \@members;
        }
    }

    return %values;
}

our sub runme ($self, $os, $debug) {
    my %values;

    if ($EUID == 0) {
        %values = get_local_groups($self, $os);
    }

    return %values;
}

true;