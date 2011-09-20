#!/usr/bin/perl

use Lab::Instrument::Dummysource;


my $src=new Lab::Instrument::Dummysource({
    fast_set                => 1,
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.1,
    gp_max_step_per_second  => 1,
    gp_min_volt             => -10,
    gp_max_volt             => 10,
});

$src->set_voltage(-4,1);

$src->set_voltage(5,3);

my $src1=new Lab::Instrument::Source($src,1);
$src1->set_voltage(-2);


my $src2=new Lab::Instrument::Source($src, 4, {
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.12,
    gp_max_step_per_second  => 1,
    gp_min_volt             => -10,
    gp_max_volt             => 10,

});
$src2->set_voltage(-1);

my $src3=new Lab::Instrument::Dummysource({
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.1,
    gp_max_step_per_second  => 1,
    gp_min_volt             => -10,
    gp_max_volt             => 10,
});

$src3->set_voltage(-4);
