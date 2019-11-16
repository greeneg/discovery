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

package Discovery::Config;

use strict;
use warnings;
use feature ":5.22";
# Add features to system for lexical subs and signatures
# disable all warnings for these as they are still experimental
# (likely won't change much though in the future...)
no warnings "experimental::lexical_subs";
no warnings "experimental::signatures";
no warnings "experimental::smartmatch";
use feature 'lexical_subs';
use feature 'signatures';
use feature 'switch';
use English;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Config;
use Discovery::Constants;
use Discovery::Logger;
use Data::Dumper;

my $VERSION = 0.1;

my %config;

sub new ($class) {
    my $self = {};
    bless $self, $class;

    return $self;
}

our sub _initialize ($self, $config, %flags) {
    my $sub = (caller(0))[3];

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__,
      ": Setting up Config object" if ($flags{debug} eq 'true');

    %config = %{$config};

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__,
      ": Setting platform defaults" if ($flags{debug} eq 'true');
    given ($self->get_os(\$config)) {
        when (/^darwin/) {
            $config{'platform_defaults'} = {
                'custom_type_directory' => [
                    "$flags{plugin_path}",
                    '/usr/local/lib/configmgr/discovery.d/',
                    '/etc/configmgr/discovery.d/'
                ]
            };
            break;
        }
        when (/^linux/) {
            $config{'platform_defaults'} = {
                'custom_type_directory' => [
                    "$flags{plugin_path}",
                    '/usr/local/lib/configmgr/discovery.d/',
                    '/etc/configmgr/discovery.d/'
                ]
            };
            break;
        }
        when (/^win32/) {
            $config{'platform_defaults'} = {
                'custom_type_directory' => [
                    "$flags{plugin_path}",
                    'C:\\ProgramData\\ConfigMgr\\discovery.d\\'
                ]
            };
            break;
        }
    }

    return %config;
}

our sub get_general_config ($self, $config, %flags) {
    my $sub = (caller(0))[3];
    say STDERR __PACKAGE__, ": $sub: ", __LINE__ if ($flags{debug} eq 'true');

    my %general_config;
    my $enable_custom = $config->val('General', 'EnableCustom');
    if ($enable_custom eq 'true' && $flags{'no_c_dir'} eq 'false') {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": load setting for custom plugin directory: $enable_custom" if ($flags{debug} eq 'true');
        $general_config{'enable_custom'} = $enable_custom;
        my $c_dir = $config->val('General', 'CustomDirectory');
        if ($c_dir ne '') {
            say STDERR __PACKAGE__, ": $sub: ", __LINE__,
              ": setting custom plugin directory to $c_dir" if ($flags{debug} eq 'true');
            $general_config{'custom_dir'}    = $c_dir;
        } else {
            say STDERR __PACKAGE__, ": $sub: ", __LINE__, 
              ": CustomDirectory setting missing, using platform defaults" if ($flags{debug} eq 'true');
            $general_config{'custom_dir'}    = '';
        }
    } else {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": EnableCustom == false, so disable option" if ($flags{debug} eq 'true');
        $general_config{'enable_custom'} = 'false';
        $general_config{'custom_dir'}    = '';
    }
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Settings enable_custom == $general_config{enable_custom}\n",
      "           custom_dir    == $general_config{custom_dir}" if ($flags{debug} eq 'true');

    unless (exists $flags{'format'}) {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": No flag given, setting OutputFormat from configuration file" if ($flags{debug} eq 'true');
        $general_config{'output_format'}    = $config->val('General', 'OutputFormat');
    } else {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": flag passed, setting OutputFormat" if ($flags{debug} eq 'true');
        $general_config{'output_format'}    = $flags{'format'};
    }
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Setting output_format == $general_config{output_format}" if ($flags{debug} eq 'true');

    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": setting path to log files" if ($flags{debug} eq 'true');
    $general_config{'debug_log'}        = $config->val('General', 'DebugLogPath');
    $general_config{'logfile'}          = $config->val('General', 'LogFilePath');
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Settings debug_log == $general_config{debug_log}\n",
      "           logfile   == $general_config{logfile}" if ($flags{debug} eq 'true');

    return %general_config;
}

our sub get_cli_config ($self, $config, %flags) {
    my $sub = (caller(0))[3];
    say STDERR __PACKAGE__, ": $sub: ", __LINE__ if ($flags{debug} eq 'true');

    my %cli_config;
    unless ($flags{debug} eq 'true') {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": setting debug setting from configuration file" if ($flags{debug} eq 'true');
        $cli_config{'debug'}     = $config->val('CLI', 'EnableDebugging');
    } else {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": debugging requested at command line, setting" if ($flags{debug} eq 'true');
        $cli_config{'debug'}     = $flags{debug};
    }
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Setting debug == $cli_config{debug}" if ($flags{debug} eq 'true');

    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": setting verbosity from configuration file" if ($flags{debug} eq 'true');
    $cli_config{'verbose'}       = $config->val('CLI', 'BeVerbose');
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Setting verbose == $cli_config{verbose}" if ($flags{debug} eq 'true');

    if ($flags{'log_lvl'} ne 'none') {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": log level requested at command line, setting" if ($flags{debug} eq 'true');
        $cli_config{'log_lvl'} = $flags{'log_lvl'}
    } else {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": setting log level from configuration file" if ($flags{debug} eq 'true');
        $cli_config{'log_lvl'} = $config->val('CLI', 'LogLevel');
    }
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Setting log_lvl == $cli_config{log_lvl}" if ($flags{debug} eq 'true');

    return %cli_config;
}

our sub load_config ($self, %flags) {
    my $sub = (caller(0))[3];
    say STDERR __PACKAGE__ . ": $sub: " . __LINE__ if ($flags{debug} eq 'true');

    # read in configuration
    my $cfg_file;
    unless (exists($flags{cfgfile})) {
        $cfg_file = File::Spec->rootdir() . "etc/discovery/config.ini";
    } else {
        say STDERR __PACKAGE__, ": $sub: ", __LINE__,
          ": config file option passed: $flags{cfgfile}" if ($flags{debug} eq 'true');
        if (-f $flags{cfgfile}) {
            say STDERR __PACKAGE__, ": $sub: ", __LINE__,
              ": $flags{cfgfile} exists" if ($flags{debug} eq 'true');
            $cfg_file = $flags{'cfgfile'};
        } else {
            say STDERR "Configuration File Not Found. Exiting.";
            exit -1;
        }
    }
    my $cfg      = Config::IniFiles->new(-file => $cfg_file);

    my %general_config = $self->get_general_config($cfg, %flags);
    my %cli_config     = $self->get_cli_config($cfg, %flags);

    # turn this into a merged configuration hash
    my %config = (
        'general' => \%general_config,
        'cli'     => \%cli_config,
    );

    %config = $self->_initialize(\%config, %flags);

    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": dump of configuration structure" if ($flags{debug} eq 'true');
    say STDERR Dumper %config if ($flags{debug} eq 'true');

    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": Returning configuration structure" if ($flags{debug} eq 'true');
    return %config;
}

our sub get_os ($self, $config) {
    my $sub = (caller(0))[3];
    say STDERR __PACKAGE__, ": $sub: ", __LINE__ if ($config{cli}->{debug} eq 'true');

    my $os;
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": OPERATING SYSTEM: $Config{osname}" if ($config{cli}->{debug} eq 'true');
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": OPERATING SYSTEM: $Config{archname}" if ($config{cli}->{debug} eq 'true');
    say STDERR __PACKAGE__, ": $sub: ", __LINE__,
      ": OPERATING SYSTEM VERSION: $Config{osvers}" if ($config{cli}->{debug} eq 'true');

    $os = $Config{osname};

    return $os;
}

1;
