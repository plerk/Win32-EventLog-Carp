package Win32::EventLog::Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( confess carp croak );
@EXPORT_OK = qw( cluck );

$VERSION = '0.02';

require Carp;
use Win32::EventLog;

sub carp
{
    my $warning = Carp::shortmess(@_);
    &_report( EVENTLOG_WARNING_TYPE, $warning );
    warn $warning;
}

sub croak
{
    my $warning = Carp::shortmess(@_);
    &_report( EVENTLOG_ERROR_TYPE, $warning );
    die $warning;
}

sub confess
{
    my $warning = Carp::longmess(@_);
    &_report( EVENTLOG_ERROR_TYPE, $warning );
    die $warning;
}

sub cluck
{
    my $warning = Carp::longmess(@_);
    &_report( EVENTLOG_WARNING_TYPE, $warning );
    warn $warning;
}

sub _report
{
    my ($event_type, $event_text) = @_;
    my $eh = Win32::EventLog->new('Application');

    my %ReportHash = (
	EventType => $event_type,
	Source => $0,
	Strings => $event_text . "\x00"
    );

    $eh->Report( \%ReportHash );

    $eh->Close();
}


1;
__END__

=head1 NAME

Win32::EventLog::Carp - for carping in the Windows NT Event Log

=head1 SYNOPSIS

  use Win32::EventLog::Carp;

  my $code = &something() or croak "Unable to do something";

  unless ($code)
  {
      carp "Nothing from something";
  }

=head1 DESCRIPTION

Win32::EventLog::Carp is a wrapper for the Carp module so that messages are
added to the Windows NT Event Log. This is useful for Perl scripts which run
as services or through the scheduler.

The interface is the same as Carp and it should function in the same way
(though it hasn't been tested as thoroughly).

=head1 REQUIREMENTS

  Carp
  Win32::EventLog

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 SEE ALSO

Win32::EventLog, Carp

=cut
