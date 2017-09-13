#!/usr/bin/env perl -T
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

    say STDERR __PACKAGE__, ': ', "$sub: ", __LINE__, ": Setting up Config object" if $flags{debug};

    %config = %{$config};

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
    my %general_config;
    $general_config{'custom_dir'}       = $config->val('General', 'CustomDirectory');
    $general_config{'enable_custom'}    = $config->val('General', 'EnableCustom');
    $general_config{'output_format'}    = $config->val('General', 'OutputFormat');
    $general_config{'debug_log'}        = $config->val('General', 'DebugLogPath');
    $general_config{'logfile'}          = $config->val('General', 'LogFilePath');

    return %general_config;
}

our sub get_cli_config ($self, $config, %flags) {
    my %cli_config;
    unless (exists $flags{debug}) {
        $cli_config{'debug'} = $config->val('CLI', 'EnableDebugging');
    } else {
        $cli_config{'debug'} = $flags{debug};
    }
    $cli_config{'trace'}     = $config->val('CLI', 'EnableTracing');
    $cli_config{'verbose'}   = $config->val('CLI', 'BeVerbose');
    $cli_config{'log_level'} = $config->val('CLI', 'LogLevel');

    return %cli_config;
}

our sub load_config ($self, %flags) {
    # read in configuration
    my $cfg_file;
    unless (exists($flags{cfgfile})) {
        $cfg_file = File::Spec->rootdir() . "etc/discovery/config.ini";
    } else {
        if (-f $flags{cfgfile}) {
            $cfg_file = $flags{'config_file'};
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

    return %config;
}

our sub get_os ($self, $config) {
    my $sub = (caller(0))[3];

    my $os;

    say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__, ": OPERATING SYSTEM: $Config{osname}" if $config{cli}->{debug};
    say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__, ": OPERATING SYSTEM: $Config{archname}" if $config{cli}->{debug};
    say STDERR __PACKAGE__, ': ', $sub, ': ', __LINE__, ": OPERATING SYSTEM VERSION: $Config{osvers}" if $config{cli}->{debug};

    $os = $Config{osname};

    return $os;
}

1;
