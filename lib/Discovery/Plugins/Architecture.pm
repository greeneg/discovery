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

package Discovery::Plugins::Architecture;

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
use Config;
use POSIX;

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;   
}

our sub isX86Capable ($self, $os, $os_ver, $hw) {
    my $retval = 'false';

    if ($hw eq 'x86_64') {
        $retval = 'true';
        if ($os eq 'darwin') {
            my $os_maj_ver = substr($os_ver, 0, 2); # get the os series
            if ($os_maj_ver >= '18') {
                $retval = 'false'; # darwin 19 dropped 32bit support
            }
        }
    }

    return $retval;
}

our sub runme ($self, $os, $debug) {
    my %values;
    if ($os eq 'darwin' || $os eq 'linux') {
        my (undef, undef, $os_ver, undef, $hw) = POSIX::uname();
        $values{'Architecture'}->{'architecture'}  = $hw;
        $values{'Architecture'}->{'32bit_capable'} = $self->isX86Capable($os, $os_ver, $hw);
    }

    return %values;
}

true;
