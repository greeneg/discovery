use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                   => 'discovery',
    AUTHOR                 => q{Gary Greene <greeneg@tolharadys.net>},
    VERSION_FROM           => 'lib/Discovery/Constants.pm',
    ABSTRACT               => 'Discover and Report Useful Information From the Local System',
    MIN_PERL_VERSION       => 5.18,
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'apachev2')
      : ()),
    PL_FILES               => {},
    PREREQ_PM => {
        'Config::IniFiles' => 2.90,
        'FindBin'          => 1.50,
        'Test::More'       => 0,
        'JSON::XS'         => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                  => { FILES => 'discovery-*' },
    test                   => { TESTS => 't/*.t' }
);
