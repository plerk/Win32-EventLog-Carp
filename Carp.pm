package Win32::EventLog::Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( confess carp croak );
@EXPORT_OK = qw( cluck click );

$VERSION = '0.04';

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

sub click
{
    my $warning = join("", @_) . "\n"; # Carp joins elements w/no separator
    &_report( EVENTLOG_INFORMATION_TYPE, $warning );
    print STDERR $warning;
}

sub _report
{
    my ($event_type, $event_text) = @_;

    $event_text =~ s/\n(?!\z)/\; /g; # change newlines to semicolons
    $event_text =~ s/\n\z//;

    my $eh = Win32::EventLog->new('Application');

    my %ReportHash = (
	EventType => $event_type,
	Source => $0,
	Strings => $event_text
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

The interface is basically the same as Carp and it should function in the
same way (though it has not been tested as thoroughly). You need only change
references of "Carp" to "Win32::EventLog::Carp" to begin using this module.

One notable exception is the addition of the I<click> function:

  Win32::EventLog::Carp::click "Make a jazz noise here.";

This outputs the message to STDERR without a stack trace, and allows scripts\
to post a simple "I have started" or "I am doing XYZ now" message to the log.

All messages are posted the the Application Log we well as to STDERR.

=head1 REQUIREMENTS

  Carp
  Win32::EventLog

=head1 BUGS

Any bugs in Win32::EventLog and Carp will lead to bugs with this module.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 SEE ALSO

Win32::EventLog, Carp

=cut
