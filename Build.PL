use Module::Build;

# requires_os: MSWin32

my $build = Module::Build->new
    (
     module_name => 'Win32::EventLog::Carp',
     license => 'perl',
     requires => {
       'perl'                       => '5.005',
       'Carp'                       => 0,
       'Carp::Heavy'                => 0,
       'File::Basename'             => 0,
       'File::Spec'                 => 0,
       'Win32::EventLog'            => 0,
     },
     recommends => {
       'Win32::EventLog::Message'   => 0,
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
