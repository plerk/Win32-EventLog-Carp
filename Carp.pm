package Win32::EventLog::Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA       = qw( Exporter Carp );
@EXPORT    = qw( confess carp croak );
@EXPORT_OK = qw( cluck click register_source );

$VERSION   = '1.11';

use Carp;

use File::Basename qw( basename );
use File::Spec qw( rel2abs );

use Win32::EventLog;

my ($log, $source, $filename);

sub import
  {
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
      {
	$source = $_->{Source};
      }

    @_ = ($package, @exports);
    goto &Exporter::import;
  }

sub register_source

# If the Win32::EventLog::Message module is available, register the source
# with the Windows NT event log (this only works if the user has the proper
# permissions). This removes the 'description not found' warning in when
# looking at the event in the event log viewer.

# Needs to check if a log is created, and if so, close it and then reopen it.

  {
    my ($log_name, $source_name) = @_;

    eval {
      require Win32::EventLog::Message;
      import Win32::EventLog::Message;
      Win32::EventLog::Message::RegisterSource( $log_name, $source_name );
    };    

    if ($@)
      {
	CORE::warn "Unable to register source \`$source_name\' in \`$log_name\' log";
      }
  }

sub _report

# Reports an event in the Windows NT event log.

  {

    unless ($log)
      {
	Win32::EventLog::Carp::register_source( "Application", $source );

	# Create a handle to the Windows NT event log (we do this in the BEGIN
	# block so that we can trap some compilation errors).

	$log    = Win32::EventLog->new( $source )
	  or CORE::die "Unable to initialize Windows NT event log";

      }

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

    $event_text = join(": ", $filename, $event_text);

    $event_text =~ s/\x0/; /g;                # only one string is used
    $event_text =~ s/(\r?\n){1,}(?!\z)/\; /g;
    $event_text =~ s/\r?\n\z//;

    my $event = {
		 EventID   => 0,
		 EventType => $event_type,
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
    # There are hooks for defining our own Source and Log

    $filename = File::Spec->rel2abs( $0 );

    unless ($source)
      {

	# We use the basename of the file because registry keys cannot have
	# slashes in them. Of course since we are registering an event source
	# (only if we have admin privs) we'll include the full patch in the
	# event text (after all, an error in 'index.pl' doesn't tell us which
	# one).

	$source =  File::Basename::basename( $filename );
      }

    # If there's already a handler, we just report the error to the log and
    # go to the existing handler (so we assume the other handler does what
    # it should); otherwise we use our own.

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

sub _closelog()
  {
    if ($log)
      {
	$log->Close();
	$log = undef;
      }
  }

END
  {

    # Make sure we clean up after ourselves!
    _closelog();
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

The module will use C<Win32::EventLog::Message> to register itself as a
source, if that module is installed.

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

=head2 Event Source Registration

If the C<Win32::EventLog::Message> module is installed on the system, I<and if
the script is run with the appropriate (Administrator) permissions>, then
Perl program will attempt register itself as an event source. Which means
that

  carp "Hello";

will produce something like

  Hello at script.pl line 10

rather than

  The description for Event ID ( 0 ) in Source ( script.pl ) could
  not be found. It contains the following insertion string(s): Hello
  at script.pl line 10.

=head2 Redefining Event Sources

You can specify a different event source. The following

  use Win32::EventLog::Carp qw(cluck carp croak click confess),
        {
          Source => 'MyProject',
	};

will list the source as "MyProject" rather than the filename. Future
versions of the module may allow you to post events in the System or
Security logs.

This feature should be considered experimental.

Caveat: the effect of multiple modules using C<Win32::EventLog::Carp>
with sources set and which call each other may have funny interactions.
This has not been thoroughly tested.

=head1 KNOWN ISSUES

We use the basename of the script as the event source, rather than the full
pathname. This allows us to register the source name (since we cannot have
slashes in registered event log source names). The downside is that we have
to view the event text to see which script it is (for common script names
in a web site, for instance).

=head1 SEE ALSO

  Carp
  CGI::Carp
  Win32::EventLog
  Win32::EventLog::Message

C<Win32::EventLog::Message> can be found at http://www.roth.net/perl/packages/

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 LICENSE

Copyright (c) 2000-2001 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
