#-*- mode: perl;-*-

use Test::More tests => 2;

require Win32;
ok(1);

if (Win32::WinNT) {
  require Win32::EventLog::Carp;
  import Win32::EventLog::Carp 1.32;
}
else {
  require Carp;
  import Carp;
}
ok(1);
