package Win32::EventLog::Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA       = qw( Exporter Carp );
@EXPORT    = qw( confess carp croak );
@EXPORT_OK = qw( cluck click );

$VERSION   = '1.00';

use Carp;
use Win32::EventLog;

my ($log);

sub _report

# Reports an event in the Windows NT event log.

  {
    # If for some reason the log isn't initialized...!

    unless ($log)
      {
	CORE::die
	  "Win32::EventLog not initialized in Win32::EventLog::Carp";
	return;
      }

    my ($event_type, $event_text) = @_;

    # Change newlines to semicolons ('; ') since they do not show up well in
    # the event log viewer (does Windows 2000 handle newlines better?)

    $event_text =~ s/(\r?\n){1,}(?!\z)/\; /g;
    $event_text =~ s/\r?\n\z//;

    my $event = {
		 EventType => $event_type,
		 Source    => $0,
		 Strings   => $event_text
		};

    $log->Report( $event );
  }

sub _warn
  {
    _report( EVENTLOG_WARNING_TYPE, @_ );
    CORE::warn @_;
  }

sub _die
  {
    _report( EVENTLOG_ERROR_TYPE, @_ );
    CORE::die @_; 
  }


BEGIN
  {

    # Create a handle to the Windows NT event log (we do this in the BEGIN
    # block so that we can trap some compilation errors).

    $log    = Win32::EventLog->new('Application')
      or die "Unable to initialize Windows NT event log";

    # If there's already a handler, we just report the error to the log and
    # go to the existing handler; otherwise we use our own.

    if ($SIG{__WARN__})
      {
	my $previous = $SIG{__WARN__};
	$SIG{__WARN__} = sub {
	  _report( EVENTLOG_WARNING_TYPE, @_ );
	  return &$previous;
	};
      }
    else
      {
	$SIG{__WARN__} = \&Win32::EventLog::Carp::_warn;
      }

    if ($SIG{__DIE__})
      {
	my $previous = $SIG{__DIE__};
	$SIG{__DIE__} = sub {
	  _report( EVENTLOG_ERROR_TYPE, @_ );
	  return &$previous;
	};
      }
    else
      {
	$SIG{__DIE__} = \&Win32::EventLog::Carp::_die;
      }

  }

END
  {

    # Make sure we clean up after ourselves!

    if ($log)
      {
	$log->Close();
      }
  }

sub carp    { CORE::warn Carp::shortmess @_;    }
sub croak   { CORE::die  Carp::shortmess @_;   }
sub cluck   { CORE::warn Carp::longmess @_;   }
sub confess { CORE::die  Carp::longmess @_; }

sub click
  {
    my $message = Carp::shortmess(@_);
    &_report( EVENTLOG_INFORMATION_TYPE, $message );
    print STDERR $message;
  }

1;
__END__

=head1 NAME

Win32::EventLog::Carp - for carping in the Windows NT Event Log

=head1 REQUIREMENTS

  Carp
  Win32::EventLog

=head1 SYNOPSIS

  use Win32::EventLog::Carp;
  croak "We're outta here!";

  use Win32::EventLog::Carp qw(cluck);
  cluck "This is how we got here!";

=head1 DESCRIPTION

C<Win32::EventLog::Carp> traps warnings and fatal errors in Perl and reports
these errors in the Windows NT Event Log. This is useful for scripts which
run as services or through the scheduler, and for CGI/ISAPI scripts.

The interface is similar to C<Carp>: the C<carp>, C<croak> and C<confess>
functions are exported (with C<cluck> being optional).  You need only change
references of "Carp" to "Win32::EventLog::Carp" to begin using this module.

One notable exception is the addition of the C<click> function:

  Win32::EventLog::Carp::click "Hello!\n";

This outouts a message to STDERR with a short stack trace and allows scripts
to post a simple "I have started" or "I am doing XYZ now" message to the log.
To avoid the stack trace, end the message with a newline (which is what
happens with the C<Carp> module).

All messages are posted the the Application Log we well as to STDERR.

=head2 Using Win32::EventLog::Carp with CGI::Carp

Some modules which trap the C<__WARN__> and C<__DIE__> signals are not very
friendly, and will cancel out existing traps. The solution is to use this
module I<after> using other modules:

  use CGI::Carp;
  use Win32::EventLog::Carp

or

  BEGIN
    {
      $SIG{__WARN__} = \&my_handler;
    }

  use Win32::EventLog::Carp

It is assumed that the previous handler will properly C<warn> or C<die> as
appropriate. This module will instead report these events to the NT event
log.

=head2 eval and die

This module I<will> log errors in the event log when something dies in an
eval.  This is a feature, not a bug.

=head1 BUGS

Bugs in C<Win32::EventLog> and C<Carp> may lead to bugs with this
module.

=head1 SEE ALSO

  Carp
  CGI::Carp
  Win32::EventLog

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 LICENSE

Copyright (c) 2000-2001 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
