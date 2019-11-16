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

package Discovery::Util;

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

use Discovery::Constants;
use Discovery::Config;
use Discovery::Logger;
use Data::Dumper;
use File::Basename;
use JSON::XS;
use Module::Pluggable::Object;
use YAML::XS;

our $VERSION = 0.1;

# private variables
my %config;
my $DEBUG;
my $conf;

sub new ($class, $config, $DEBUG) {
    my $self = {};
    bless $self, $class;

    # now set the local variables for the class
    $self->_initialize($config, $DEBUG);

    return $self;
}

our sub _initialize ($self, $config, $debug) {
    my $sub = (caller(0))[3];

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__, ": Setting up Util object" if ($debug eq 'true');

    $conf = Discovery::Config->new();
    %config = %{$config};
    $DEBUG = $debug;
}

our sub app_name ($self, $exe) {
    my $appname = basename($exe);

    return $appname;
}

our sub print_help {
    say "$Discovery::Constants::title $Discovery::Constants::version";
    say "=====================";
    say "";
    say "Synopsis:";
    say "---------";
    say "Discover and report useful information about a system";
    say "";
    say "Usage:";
    say "------";
    say "    ", app_name(undef, $0), " [-h|--help] [-v|--version] [-d|--debug] [-t|--trace]";
    say "      [-f|--format=<json|perleval>] [-c|--config=CONFIG_FILE]";
    say "      [--short-version] [-x|--custom-dir=DIRECTORY] [--no-custom-dir]";
    say "      [-l|--log-level=<none|debug|info|notice|warning|error|critical|alert|emergency>]";
    say "";
    say "Description:";
    say "------------";
    say "Discover and report useful information about the current running system for use";
    say "with the CfgMgr client and server. The backend to the application is an easily";
    say "extensible collection of Perl modules, allowing adding checks for new types of";
    say "information and support of any platform that Perl runs on with relative ease.";
    say "This makes gathering information about a system easy in both shell and Perl.";
    say "";
    say "If no information types are passed, all types and their values are printed in";
    say "plain key=value format";
    say "";
    say "Options:";
    say "--------";
    say "  General Options:";
    say "    -h|--help             Output this help information";
    say "    -v|--version          Output the version and copyright information";
    say "    -d|--debug            Enable debug output";
    say "    -t|--trace            Enable backtraces on errors";
    say "       --short-version    Output only the version number";
    say "  Specific Options:";
    say "    -f|--format FORMAT    Print all output in the specified format.";
    say "                          Supported formats are JSON (default), YAML, and";
    say "                          perleval";
    say "    -c|--config FILE      Use a specific configuration file";
    say "       --no-custom-dir    Disable custom type tests";
    say "    -x|--custom-dir DIR   Directory where custom types are stored";
    say "    -l|--log-level LEVEL  Set the amount of logged data printed based on a syslog";
    say "                          like set of levels:";
    say "                            * none: prints no extra logging messages";
    say "                            * debug: prints debug logging messages";
    say "                            * info: prints informational logging messages";
    say "                            * warning: prints warning logging messages";
    say "                            * error: prints error logging messages";
    say "                            * critical: prints critical logging messages";
    say "                            * alert: prints alert logging messages";
    say "                            * emergency: prints emergency logging messages";
    say "";
    say "Examples:";
    say "--------";
    say "Discover all:";
    say "";
    say "    \$ discovery";
    say "    architecture=x86_64";
    say "    block_devices=sda,sdb,sdc";
    say "    domain=example.com";
    say "    fqdn=host.example.com";
    say "    [....]";
    say "";
    say "Discover a single type:";
    say "";
    say "    \$ discovery domain";
    say "    domain=example.com";
    say "";
    say "Format output as JSON:";
    say "";
    say "    \$ discovery --format=json architecture kernel hw_type";
    say "    {";
    say "      \"architecture\": \"x86_64\"";
    say "      \"kernel\": \"Darwin\"";
    say "      \"hw_type\": \"physical\"";
    say "    }";
    say "";
    say "Author:";
    say "-------";
    say "  $Discovery::Constants::author";
    say "";
    say "License:";
    say "--------";
    say "  $Discovery::Constants::license";
}

our sub print_version {
    say "$Discovery::Constants::title $Discovery::Constants::version";
    say "$Discovery::Constants::copyright";
    say "$Discovery::Constants::license";
    say "Author: $Discovery::Constants::author";
}

our sub discovery_loop ($self, $config, $log, $debug_log, $debug) {
    my $logger = Discovery::Logger->new(\%config, $debug);
    my $sub = (caller(0))[3];

    my $os = $conf->get_os($config);

    # deref the config reference back to a hash
    my %config = %{$config};
    if (! defined($debug)) {
        $debug = 0;
    }

    our @plugin_dirs = @{$config{'platform_defaults'}->{'custom_type_directory'}};
    if ($config{cli}->{debug}) {
        say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__,
          ': Plugin Search Directories: ' if ($debug eq 'true');
        foreach my $dir (@plugin_dirs) {
            say STDERR "\t$dir" if ($debug eq 'true');
        }
    }

    my $finder = Module::Pluggable::Object->new(
        require => 1,
        search_dirs => \@plugin_dirs,
        search_path => 'Discovery::Plugins',
    );

    # generate path
    my %value;
    my %values;
    foreach my $plugin ($finder->plugins) {
        say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__,
          ": Plugin: $plugin" if ($config{cli}->{debug} eq 'true');
        %value = $plugin->runme($os, $debug);
        %values = (%values, %value);
    }

    my $json;
    if ($config{'general'}->{'output_format'} eq 'json') {
        $json = JSON::XS->new;
        $json = $json->convert_blessed([1]);
        $json = $json->pretty;
        print $json->encode(\%values);
    } elsif ($config{'general'}->{'output_format'} eq 'yaml') {
        print Dump(\%values);
    } elsif ($config{'general'}->{'output_format'} eq 'perleval') {
        print Dumper(\%values);
    }
}

1;
