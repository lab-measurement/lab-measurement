#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use lib qw(../lib);
use Data::Dumper;
use Test::More tests => 47;

use Lab::Measurement;
use Scalar::Util qw(looks_like_number);

my $query;
my $yoko = Instrument('Yokogawa7651', {connection_type => 'LinuxGPIB',
				       gpib_address => 11,
				       gate_protect => 0,});

# function

for my $function (qw/current voltage/) {
	$yoko->set_function($function);
	my $query = $yoko->get_function();
	is($query, $function, "function set to $function");
}

# range
my @ranges = qw/10e-3 100e-3 1 10 30/;
my @return_ranges = qw/12e-3 120e-3 1.2 12 32/;
    
for (my $i = 0; $i < @ranges; ++$i) {
	$yoko->set_range($ranges[$i]);
	my $query = $yoko->get_range();
	ok($query == $return_ranges[$i], "range set to " . $ranges[$i]);
}

# level

my $level = 0.1234;

$yoko->set_range(1);
$yoko->set_level($level);
$query = $yoko->get_level();
ok($level == $query, "level set to $level");

# Test voltage sweeps

# sweep with "mode => step" and jump => 1

my $sweep = Sweep('Voltage', {
	instrument => $yoko,
	mode => 'step',
	jump => 1,
	points => [1,1.01],
	stepwidth => [0.001],
	rate => [0.1],
		  });

my $expected_value = 1;
my $DataFile = DataFile('Somefile');

my $step_measurement = sub {
	my $sweep = shift;
	my $value = $yoko->get_level(# {read_mode => 'cache'}
	    );
	# we do not seem to have exact floating point equality.
	# So we have to use relative_error.
	ok(relative_error($value, $expected_value) < 1e-6, "sweep is at '$value' == '$expected_value'");
	if ($value != 1.01) {
		# we need this check, as this function seems to be called twice
		# for the final value.
		$expected_value += 0.001;
	}
};

$DataFile->add_measurement($step_measurement);
$sweep->add_DataFile($DataFile);
$yoko->set_range(10);
$yoko->_set_level(0.99);

diag("testing sweep with 'mode => step' and 'jump => 1'");
$sweep->start;
	
# sweep with "mode => list" and jump => 0
my @points = qw/0.125 0.25 0.5 1/;
$sweep = Sweep('Voltage', {
	instrument => $yoko,
	mode => 'list',
	jump => 0,
	points => \@points,
	rate => [0.1],
		  });

$DataFile = DataFile('Somefile');

my $point_index = 0;

my $list_measurement = sub {
	my $sweep = shift;
	my $value = $yoko->get_level({read_mode => 'cache'});
	my $expected_value = $points[$point_index];
	ok(float_equal($value, $expected_value), "sweep is at $expected_value");
	if ($expected_value != 1) {
		# we need this check, as this function seems to be called twice
		# for the final value.
		++$point_index;
	}
};

$DataFile->add_measurement($list_measurement);
$sweep->add_DataFile($DataFile);
$yoko->_set_level(0);
diag("testing sweep with 'mode => list' and 'jump => 0'");
$sweep->start;


# sweep with "mode => step" and jump => 0

$sweep = Sweep('Voltage', {
	instrument => $yoko,
	mode => 'step',
	jump => 0,
	points => [1,1.01],
	stepwidth => [0.001],
	rate => [0.01],
		  });

$expected_value = 1;
$DataFile = DataFile('Somefile');

$step_measurement = sub {
	my $sweep = shift;
	my $value = $yoko->get_level({read_mode => 'cache'});
	# we do not seem to have exact floating point equality.
	# So we have to use relative_error.
	ok(float_equal($value, $expected_value), "sweep is at '$value' == '$expected_value'");
	if ($value != 1.01) {
		# we need this check, as this function seems to be called twice
		# for the final value.
		$expected_value += 0.001;
	}
};

$DataFile->add_measurement($step_measurement);
$sweep->add_DataFile($DataFile);
$yoko->set_range(10);
$yoko->_set_level(0.99);

diag("testing sweep with 'mode => step' and 'jump => 0'");
$sweep->start;

# sweep with "mode => continous"

$sweep = Sweep('Voltage', {
	instrument => $yoko,
	mode => 'continuous',
	jump => 0,
	interval => 1,
	points => [1,1.01],
	rate => [0.001],
		  });

$expected_value = 1;
$DataFile = DataFile('Somefile');

my $continuous_measurement = sub {
	my $sweep = shift;
	my $value = $yoko->get_level();
	# we do not seem to have exact floating point equality.
	# So we have to use relative_error.
	
	ok(float_equal($value, $expected_value), "sweep is at '$value' == '$expected_value'");
	if ($value != 1.01) {
		# we need this check, as this function seems to be called twice
		# for the final value.
		$expected_value += 0.001;
	}
};

$DataFile->add_measurement($continuous_measurement);
$sweep->add_DataFile($DataFile);
$yoko->set_range(10);
$yoko->_set_level(0.99);

diag("testing sweep with 'mode => continuous'");
$sweep->start;


sub relative_error {
	my $a = shift;
	my $b = shift;
	return abs(($b - $a) / $b);
}

sub float_equal {
	my $a = shift;
	my $b = shift;
	return (relative_error($a, $b) < 1e-6);
}