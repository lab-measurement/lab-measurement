#!/usr/bin/perl
#$Id$

use strict;
use Test::More tests => 3;

BEGIN { use_ok('VISA::Instrument::KnickS252') };

ok(my $knick=new VISA::Instrument::KnickS252("252"),'Open any Knick');
ok(my $voltage=$knick->get_voltage(),'get_voltage()');
diag "read $voltage";
