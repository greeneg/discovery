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
use Net::Interface qw(:lower);
use POSIX;

use constant INET  => 2;
use constant INET6 => 30;

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;
}

our sub runme ($self, $os) {
    my %values;

    my @interfaces = Net::Interface->interfaces();

    for my $interface (@interfaces) {
        my $int_info = $interface->info();

        my @ipv4_addresses = $interface->address(INET);
        my @ipv6_addresses = $interface->address(INET6);

        my @converted_addresses;
        foreach my $addr (@ipv4_addresses) {
            if (exists $int_info->{'2'}) {
                if ($int_info->{'2'}->{'size'} eq 4) {
                    push(@converted_addresses, Net::Interface::inet_ntoa($addr));
                }
            }
        }
        foreach my $addr (@ipv6_addresses) {
            if (exists $int_info->{'30'}) {
                if ($int_info->{'30'}->{'size'} eq 16) {
                    push(@converted_addresses, Net::Interface::ipV6compress(Net::Interface::full_inet_ntop($addr)));
                }
            }
        }

        $values{'Network'}->{'Interfaces'}->{$interface}->{'name'} = "$interface";
        $values{'Network'}->{'Interfaces'}->{$interface}->{'address'} = \@converted_addresses;
        $values{'Network'}->{'Interfaces'}->{$interface}->{'mac'} = "";
        $values{'Network'}->{'Interfaces'}->{$interface}->{'mask'} = "";
    }

    return %values;
}

1;
