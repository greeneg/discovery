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

package Discovery::Plugins::Disks;

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

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;   
}

my sub get_physical_disk_ids ($self, $os, $debug) {
    my @disks;

    if ($os eq "linux") {
        opendir my $devfs, "/dev";
        my @dentries = readdir $devfs;
        closedir $devfs;

        foreach my $dentry (@dentries) {
            next if $dentry eq '.';
            next if $dentry eq '..';
            if ($dentry =~ m/^sd[a-z]+$/) {
                push @disks, $dentry;
            } elsif ($dentry =~ m/^hd[a-z]+$/) {
                push @disks, $dentry;
            } elsif ($dentry =~ m/^nvme[0-9]+n[0-9]+$/) {
                push @disks, $dentry;
            }
        }
    }

    return @disks;
}

my sub linux_get_disk_model ($self, $disk, $debug) {
    open(my $model_file, "/sys/block/$disk/device/model") or
      die "Cannot open file: $OS_ERROR\n";
    my $model = readline $model_file;
    close $model_file;

    # remove unneeded white-space junk
    $model =~ s/\s+$|\n$//;

    return $model;
}

my sub linux_get_disk_serial_number ($self, $disk, $debug) {
    open(my $serial_file, "/sys/block/$disk/device/serial") or
      die "Cannot open file: $OS_ERROR\n";
    my $serial = readline $serial_file;
    close $serial_file;

    $serial =~ s/\s+$|\n$//;

    return $serial;
}

my sub linux_get_device_info ($self, $disk, $debug) {
    my @parted_output = qx(/usr/sbin/parted -l -m);

    my ($device_node, $device_size, $device_class, $device_logical_sector_size,
        $device_physical_sector_size, $device_parttype, undef, undef) = split(':', $parted_output[1]);

    my %device_info = (
        'node' => $device_node,
        'size' => $device_size,
        'class' => $device_class,
        'logical_sector_size' => $device_logical_sector_size,
        'physical_sector_size' => $device_physical_sector_size,
        'partition_type' => $device_parttype
    );

    return \%device_info;
}

my sub linux_get_disk_wwid ($self, $disk, $debug) {
    open(my $wwid_file, "/sys/block/$disk/wwid") or
      die "Cannot open file: $OS_ERROR\n";
    my $wwid = readline $wwid_file;

    chomp $wwid;

    return $wwid;
}

my sub get_disk_properties ($self, $os, $disks_ref, $debug) {
    my @disks = @{$disks_ref};

    my %disk_info = ();
    foreach my $disk (@disks) {
        if ($os eq "linux") {
            my $device_model    = linux_get_disk_model($self, $disk, $debug);
            my $device_serial_number = linux_get_disk_serial_number($self, $disk, $debug);
            my $device_info     = linux_get_device_info($self, $disk, $debug);
            my $disk_wwid       = linux_get_disk_wwid($self, $disk, $debug);

            $disk_info{$disk} = $device_info;
            $disk_info{$disk}->{'model'} = $device_model;
            $disk_info{$disk}->{'serial_number'} = $device_serial_number;
            $disk_info{$disk}->{'wwid'} = $disk_wwid;
        }
    }

    return %disk_info;
}

our sub runme ($self, $os, $debug) {
    my %values;

    if ($EUID == 0) {
        my @disks = get_physical_disk_ids($self, $os, $debug);
        my %disk_info = get_disk_properties($self, $os, \@disks, $debug);

        foreach my $disk (@disks) {
            $values{'LocalDisks'}->{$disk} = $disk_info{$disk};
        }
    }
    return %values;
}

true;
