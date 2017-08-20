# Discovery

A tool that discovers and reports useful information about a system. When it
is run, it gathers up "truths" as heirarchical key/value pairs and reports
them as JSON, simple key/value data, or as a Perl Hash structure for use by
many tools.

## Usage

    discovery [-h|--help] [-v|--version] [-d|--debug] [-t|--trace]
      [-f|--format=<json|perleval>] [-c|--config=CONFIG_FILE]
      [-e|--external-dir=DIR] [--short-version] [--no-external-dir]
      [-l|--log-level=<none|debug|info|notice|warning|error|critical|alert|emergency>]
      [--no-custom-dir]

## Description

Discover and report useful information about the current running system for use
with the CfgMgr client and server. The backend to the application is an easily
extensible collection of Perl modules, allowing adding checks for new types of
information and support of any platform that Perl runs on with relative ease.
This makes gathering information about a system easy in both shell and Perl.

If no information types are passed, all types and their values are printed in
plain key=value format

## Options

### General Options

    -h|--help             Output this help information
    -v|--version          Output the version and copyright information
    -d|--debug            Enable debug output
    -t|--trace            Enable backtraces on errors
    --short-version       Output only the version number

### Specific Options

    -f|--format FORMAT    Print all output in the specified format.
                          Supported formats are plain (the default), JSON, and
                          perleval
    -c|--config FILE      Use a specific configuration file
    -e|--external-dir DIR The directory where external type tests are installed
    --no-external-dir     Disable external type tests
    --no-custom-dir       Disable custom type tests
    -l|--log-level LEVEL  Set the amount of logged data printed based on a syslog
                          like set of levels:
                            * none: prints no extra logging messages
                            * debug: prints debug logging messages
                            * info: prints informational logging messages
                            * warning: prints warning logging messages
                            * error: prints error logging messages
                            * critical: prints critical logging messages
                            * alert: prints alert logging messages
                            * emergency: prints emergency logging messages

# Examples

Discover all:

    $ discovery
    architecture=x86_64
    block_devices=sda,sdb,sdc
    domain=example.com
    fqdn=host.example.com
    [....]

Discover a single type:

    $ discovery domain
    domain=example.com

Format output as JSON:

    $ discovery --format=json architecture kernel hw_type
    {
      "architecture": "x86_64"
      "kernel": "Darwin"
      "hw_type": "physical"
    }

# Author

  Gary L. Greene, Jr.

# License

  Licensed under the Apache Public License version 2.0

