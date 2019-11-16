#!/usr/bin/env perl
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

package Discovery::Constants;

use strict;
use warnings;
use English;
use utf8;

BEGIN {
    use Exporter   ();

    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
    $VERSION     = 1.0;
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    %EXPORT_TAGS = ( All => [ qw($version $author $license $title $copyright) ] );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw($version $author $license $title $copyright);
}

our @EXPORT_OK;

# exported package globals go here
our $author;
our $version;
our $copyright;
our $license;
our $title;

# initialize package globals, first exported ones
$version     = 0.6;
$author      = 'Gary L. Greene, Jr.';
$copyright   = 'Copyright 2017 YggdrasilSoft, LLC. All Rights Reserved.';
$license     = 'Licensed under the Apache Public License version 2.0';
$title       = 'StageMgr Discovery';

END { }       # module clean-up code here (global destructor)

1;  # don't forget to return a true value from the file
                
