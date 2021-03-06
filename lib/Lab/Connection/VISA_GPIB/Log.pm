package Lab::Connection::VISA_GPIB::Log;
#ABSTRACT: Add logging capability to a VISA_GPIB connection

use v5.20;

use warnings;
use strict;

use parent 'Lab::Connection::VISA_GPIB';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Log';

1;

