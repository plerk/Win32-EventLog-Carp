use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Win32::EventLog::Carp',
    'VERSION_FROM' => 'Carp.pm',
    'PREREQ_PM'	   => {
        'Carp'            => 0,
        'Win32::EventLog' => 0,
      },
    'NORECURS'     => 1,
  ($] ge '5.005') ? (
    'AUTHOR'       => 'Robert Rothenberg (rrwo@cpan.org)',
    'ABSTRACT'     => 'For carping into the Windows NT Event Log',
  ) : (),
);
