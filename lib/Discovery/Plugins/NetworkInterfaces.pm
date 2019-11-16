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

package Discovery::Plugins::NetworkInterfaces;

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
use List::MoreUtils qw(only_index);
use Net::Interface qw(:lower inet_ntoa full_inet_ntop);
use POSIX;

use constant INET  => 2;
use constant INET6 => 30;

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;
}

my sub get_mask ($self, $addr, $cvt_addr, $interface, $type, $ip_addresses, $debug) {
    say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__ if ($debug eq 'true');

    my $addr_count_struct;

    my $index = only_index { $_ eq $addr } @{$ip_addresses};
    say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
      ", Address Index for $cvt_addr: $index" if ($debug eq 'true');
    my $mask = Net::Interface::mask2cidr($interface->netmask($type, $index));
    say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
      ", Netmask in CIDR for $cvt_addr: $mask" if ($debug eq 'true');
    return $mask;
}

my sub create_addr_struct ($self, $int_info, $interface, $type, $ip_addresses, $debug) {
    say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__ if ($debug eq 'true');

    my $mask;
    my $cvt_addr;
    my $addr_info;
    my @converted_addresses;

    my $af_num;
    my $af_size;
    if ($type == INET) {
        $af_num = 2;
        $af_size = 4;
    } elsif ($type == INET6) {
        $af_num = 30;
        $af_size = 16;
    }

    foreach my $addr (@{$ip_addresses}) {
        if ($type == INET) {
            say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
              ', v4 addr: ', Net::Interface::inet_ntoa($addr) if ($debug eq 'true');
        } elsif ($type == INET6) {
            say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
              ', v6 addr: ', Net::Interface::ipV6compress(Net::Interface::full_inet_ntop($addr)) if ($debug eq 'true');
        }
        if (exists $int_info->{$af_num}) {
            say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
              ", AF type: $af_num" if ($debug eq 'true');
            if ($int_info->{$af_num}->{'size'} eq $af_size) {
                say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
                  ", AF $af_num has size $af_size" if ($debug eq 'true');
                if ($type == INET) {
                    $cvt_addr = Net::Interface::inet_ntoa($addr);
                    say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
                      ", Converted address: $cvt_addr" if ($debug eq 'true');
                } elsif ($type == INET6) {
                    $cvt_addr = Net::Interface::ipV6compress(Net::Interface::full_inet_ntop($addr));
                    say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
                      ", Converted address: $cvt_addr" if ($debug eq 'true');
                }
                $mask = get_mask($self, $addr, $cvt_addr, $interface, $af_num, $ip_addresses, $debug);
                say 'Sub: ', (caller(0))[3], ', line number: ', __LINE__,
                  ", Netmask: $mask" if ($debug eq 'true');
                $addr_info = {
                    "address" => $cvt_addr,
                    "cidr_mask" => $mask
                };
                push(@converted_addresses, $addr_info);
            }
        }
    }

    return @converted_addresses;
}

our sub runme ($self, $os, $debug) {
    my $sub = (caller(0))[3];
    say 'Sub: $sub: line number: ', __LINE__ if ($debug eq 'true');

    my %values;

    my @interfaces = Net::Interface->interfaces();

    for my $interface (@interfaces) {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": Interface: $interface" if ($debug eq 'true');
        my $int_info = $interface->info();

        say "INTERFACE DUMP: " . Dumper($interface) if ($debug eq 'true');
        my @ipv4_addresses = $interface->address(INET);
        my @ipv6_addresses = $interface->address(INET6);

        my @converted_addresses;
        push(@converted_addresses, create_addr_struct($self, $int_info, $interface,
              INET, \@ipv4_addresses, $debug));
        push(@converted_addresses, create_addr_struct($self, $int_info, $interface,
              INET6, \@ipv6_addresses, $debug));

        no warnings;
        my $hw_addr = undef;
        if ($int_info->{'mac'} ne undef) {
            $hw_addr = Net::Interface::mac_bin2hex($int_info->{'mac'});
        }
        use warnings;

        $values{'Network'}->{'Interfaces'}->{$interface}->{'name'} = "$interface";
        $values{'Network'}->{'Interfaces'}->{$interface}->{'addresses'} = \@converted_addresses;
        $values{'Network'}->{'Interfaces'}->{$interface}->{'mac'} = $hw_addr;
    }

    return %values;
}

1;
