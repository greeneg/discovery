#!/usr/bin/env perl

use strict;
use warnings;
use English;
use utf8;

use lib '../../lib';

use Discovery::Plugins::Uptime;

# run the call
my $os = ucfirst($OSNAME);
print $os, "\n";
my $format = "plain";

Discovery::Plugins::Uptime->runme($os,$format);

