
use Test::More tests => 11;

ok( Win32::IsWinNT() );

use Win32::EventLog;
ok(1);

ok(defined $ENV{COMPUTERNAME});

my $hnd = new Win32::EventLog("Application", $ENV{COMPUTERNAME});
ok(defined $hnd);

my ($oldest, $cnt1, $cnt2, $cnt3);

$hnd->GetOldest($oldest);

$hnd->GetNumber($cnt1);
ok(defined $cnt1);

BEGIN { use_ok('Win32::EventLog::Carp') };

$hnd->GetNumber($cnt2);
ok(defined $cnt2);

{
  local $TODO = "RT 5408 - ActivePerl 5.8 and Win32::EventLog";
  ok($cnt2 == $cnt1);
}

my $tag = (time() % 1000);

carp "Carp Test ($tag)";

$hnd->GetNumber($cnt2);
ok(defined $cnt2);
ok($cnt2 > $cnt1);

my $evt_id = $cnt2 + $oldest;
ok(defined $evt_id);

# {
#   local $TODO = "Other apps might write to log during test";

#   my $event;

#   $hnd->Read(EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ, $evt_id, $event);
  
#   ok( ($event->{Strings} =~ /Carp Test \((\d+)\)/) );
#   ok( ($1 == $tag) );
# }

if ($hnd) {
  $hnd->Close();
}



