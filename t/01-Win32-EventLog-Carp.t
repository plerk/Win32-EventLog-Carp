#-*- mode: perl;-*-

# WARNING: This test will write 7*NUM_ROUNDS events to the Windows NT
# event log.  (We test multiple rounds to verify that we are reading
# the record for that specific round.)

use constant NUM_ROUNDS => 2;

use Test::More tests => 13+(39*NUM_ROUNDS);

my $hnd;
my ($cnt1, $cnt2, $cnt3);

sub open_log {
  $hnd = new Win32::EventLog("Application", $ENV{COMPUTERNAME});
}

sub close_log {
  if ($hnd) { $hnd->Close; }
  $hnd = undef;
}

BEGIN {
  ok( Win32::IsWinNT(), "Win32::IsWinNT?" );
  use_ok('Win32::EventLog');

  ok($Win32::EventLog::GetMessageText = 1,
     "Set Win32::EventLog::GetMessageTest");

  open_log();
  ok(defined $ENV{COMPUTERNAME}, "COMPUTERNAME defined");

  $hnd = new Win32::EventLog("Application", $ENV{COMPUTERNAME});
  ok(defined $hnd, "EventLog Handle defined");

  # We need to verify that the just loading Win32::EventLog::Carp does
  # not cause errors or warnings that add tothe event log!

  $hnd->GetNumber($cnt1);
  ok(defined $cnt1, "Get size of event log");

  use_ok('Win32::EventLog::Carp');

  ok(!$Win32::EventLog::Carp::LogEvals, "Check LogEvals");
  $Win32::EventLog::Carp::LogEvals = 1;
  ok($Win32::EventLog::Carp::LogEvals,  "Set LogEvals");


  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");

  ok($cnt2 == $cnt1, "Check against rt.cpan.org issue \x235408");
};


my %Events = ( );

for my $tag (1..NUM_ROUNDS) {
  $cnt1 = $cnt2;

  Win32::EventLog::Carp::click "test,click,$tag";

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from click");
  $Events{"click,$tag"} = EVENTLOG_INFORMATION_TYPE;

  $cnt1 = $cnt2;

  warn "test,warn,$tag";

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from warn");
  $Events{"warn,$tag"} = EVENTLOG_WARNING_TYPE;

  $cnt1 = $cnt2;

  carp "test,carp,$tag";

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from carp");
  $Events{"carp,$tag"} = EVENTLOG_WARNING_TYPE;

  $cnt1 = $cnt2;

  Win32::EventLog::Carp::cluck "test,cluck,$tag";

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from cluck");
  $Events{"cluck,$tag"} = EVENTLOG_WARNING_TYPE;

  $cnt1 = $cnt2;
  $Win32::EventLog::Carp::LogEvals = 0;
  ok(!$Win32::EventLog::Carp::LogEvals, "Unset LogEval");
  eval {
    die "test,evaldie,$tag";
  };

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 == $cnt1, "Event log did not grow from eval die");

  $cnt1 = $cnt2;
  $Win32::EventLog::Carp::LogEvals = 1;
  ok($Win32::EventLog::Carp::LogEvals, "Set LogEval");
  eval {
    die "test,die,$tag";
  };

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from die");
  $Events{"die,$tag"} = EVENTLOG_ERROR_TYPE;

  $cnt1 = $cnt2;
  eval {
    croak "test,croak,$tag";
  };

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from croak");
  $Events{"croak,$tag"} = EVENTLOG_ERROR_TYPE;

  $cnt1 = $cnt2;
  eval {
    confess "test,confess,$tag";
  };

  $hnd->GetNumber($cnt2);
  ok(defined $cnt2, "Get size of event log");
  ok($cnt2 > $cnt1, "Event log grown from confess");
  $Events{"confess,$tag"} = EVENTLOG_ERROR_TYPE;
}

# In order to verify all of the events, we read through the event log
# until we've found all the tests that we saved for verification.  We
# do this because another application might have written to the event
# log while the tests were running.

sub _get_last_event {
  my $event = { };
  if ($hnd->Read(
    EVENTLOG_BACKWARDS_READ | EVENTLOG_SEQUENTIAL_READ, 0, $event)) {
    return $event;
  } else {
    warn "Unable to read event log";
    return;
  }
}

# use YAML 'Dump';

{
  ok((keys %Events) == (7*NUM_ROUNDS), "Events stacked to verify");

  my $filename = $0;
  $filename =~ s/\\/\\\\/g; # escape backslashes

  while ((keys %Events) && (my $event = _get_last_event())) {
#    print STDERR Dump($event);
    if ($filename =~ /$event->{Source}$/) {
      my $string = $event->{Strings};
      ok( $string =~ /test\,(\w+)\,(\d+) at $filename/,
        "Found test event from $filename" );
      my $key = "$1,$2";
      my $val = delete $Events{$key};
      ok(defined $val, "Found log entry for $key");
      ok($val == $event->{EventType}, "Verified log entry type for $key");
    }
  }
  ok((keys %Events)==0, "All events verified");
}



END {
  close_log();
}


