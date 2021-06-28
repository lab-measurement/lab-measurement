#PODNAME: dualchannel_sweep.pl
#ABSTRACT: Dual channel sweep of Keysight DSOS604A

use Lab::Moose;
use Class::Unload;
use List::Util qw/sum/;
use List::MoreUtils qw/minmax/;

use Lab::Moose::Instrument::Rigol_DG5000;
use Lab::Moose::Instrument::KeysightDSOS604A;

my $keysight = instrument(
   type => 'KeysightDSOS604A',
   connection_type => 'USB',
   connection_options => {verbose => 1},
   log_file => 'keysightdcsweep.yml'
);

my $rigol = instrument(
   type => 'Rigol_DG5000',
   connection_type => 'USB',
   connection_options => {verbose => 1},
   log_file => 'rigoldcsweep.yml'
);

$rigol->output_toggle(channel => 1, value => 'OFF');
$rigol->output_toggle(channel => 2, value => 'OFF');
$rigol->source_function_shape(channel => 1, value => 'PULSE');
$rigol->source_function_shape(channel => 2, value => 'PULSE');

# Unfortunatly the PULSE functions do not support coupling

# $rigol->write(command => ":COUPling:TYPE PHASE");
# $rigol->write(command => ":COUPling:CHannel:BASE CH1");
# $rigol->write(command => ":COUPling:PHASe:DEViation 0");
# $rigol->write(command => ":COUPling ON");

###
### SWEEP PARAMETERS
###

# pulse width (s) Min 4ns
my $wstart =  0.000005;
my $wend =    0.000015;
my $wstep =   0.000005;

# pulse delay (s)
my $dstart =  0.000100;
my $dend =    0.000200;
my $dstep =   0.000100;

# amplitude (V)
my $astart = 1;
my $aend = 1;
my $astep = 0.5;

# captured cycles
my $cycles = 2;

# location of where to save the results
my $folder = 'C:\Users\Administrator\Documents\Results\Sweep1';

# If the target directory does not exist yet, create it
if ($keysight->query(command => ":DISK:DIRectory? \"$folder\"") == 0){
  $keysight->write(command => ":DISK:MDIRectory \"$folder\"");
  $keysight->write(command => ":DISK:CDIRectory \"$folder\"");
}

###
### CONFIGURE MEASUREMENTS
###

$keysight->write(command => ":MEASure:CLEar");
$keysight->write(command => ":MEASure:STATistics ON");
$keysight->write(command => ":MEASure:SOURce CHANnel1,CHANnel2");
$keysight->write(command => ":MEASure:RISetime CHANnel1");
$keysight->write(command => ":MEASure:RISetime CHANnel2");
$keysight->write(command => ":MEASure:PWIDth CHANnel1");
$keysight->write(command => ":MEASure:PWIDth CHANnel2");
$keysight->write(command => ":MEASure:PERiod CHANnel1");
$keysight->write(command => ":MEASure:PERiod CHANnel2");
$keysight->write(command => ":MEASure:NPERiod CHANnel1,RISing,$cycles");
$keysight->write(command => ":MEASure:NPERiod CHANnel2,RISing,$cycles");
$keysight->write(command => ":ANALyze:AEDGes ON");
$keysight->write(command => ":MEASure:DUTYcycle CHANnel1");
$keysight->write(command => ":MEASure:DUTYcycle CHANnel2");
$keysight->write(command => ":MEASure:VPP CHANnel1");
$keysight->write(command => ":MEASure:VPP CHANnel2");
$keysight->write(command => ":MEASure:PHASe CHANnel1,CHANnel2");

### More setup on the Oscilloscope

$keysight->waveform_format(value => 'WORD');
$keysight->write(command => ":CHANnel1:DISPlay ON");
$keysight->write(command => ":CHANnel2:DISPlay ON");

$keysight->timebase_reference(value => 'LEFT');
$keysight->timebase_ref_perc(value => 5);

$keysight->channel_input(channel => 'CHANnel1', parameter => 'DC50');
$keysight->channel_differential(channel => 'CHANnel1', mode => 'OFF');

$keysight->channel_input(channel => 'CHANnel2', parameter => 'DC50');
$keysight->channel_differential(channel => 'CHANnel2', mode => 'OFF');

# Configure the data acquisition
$keysight->acquire_mode(value => 'HRESolution');
$keysight->acquire_hres(value => 'BITF16');
$keysight->acquire_points(value => 10000);

# Configure the trigger type
$keysight->write(command => ":TRIGger:EDGE:SOURce CHANnel1");
$keysight->write(command => ":TRIGger:EDGE:SLOPe POSitive");


sleep(1);

# Compute the total amount of measurements that need to be done
my $total = ((abs($wend-$wstart)/$wstep)+1)*((abs($dend-$dstart)/$dstep)+1)*((abs($aend-$astart)/$astep)+1);
my $c = 0;

# Iterate over all parameters in nested loops
for (my $w = $wstart; $w <= $wend; $w += $wstep) {
  for (my $d = $dstart; $d <= $dend; $d += $dstep) {
    for (my $a = $astart; $a <= $aend; $a += $astep) {
      $rigol->output_toggle(channel => 1, value => 'OFF');
      $rigol->output_toggle(channel => 2, value => 'OFF');

      # Apply all of the specific parameters to the output waveform
      $rigol->source_apply_pulse(channel => 1, freq => 1/($w+$d), amp => 2*$a, offset => $a, delay => $d);
      $rigol->write(command => ":SOURce1:PULSe:WIDTh $w");
      $rigol->source_apply_pulse(channel => 2, freq => 1/($w+$d), amp => 2*$a, offset => $a, delay => $d);
      $rigol->write(command => ":SOURce2:PULSe:WIDTh $w");


      sleep(0.2);
      $rigol->phase_align(channel => 1); # doesnt work...

      # Adjust the oscilloscopes settings according to the waveform
      $keysight->timebase_range(value => $cycles*($w+$d));
      $keysight->channel_offset(channel => 'CHANnel1', offset => $a/2);
      $keysight->channel_range(channel => 'CHANnel1', range => $a*1.15);
      $keysight->channel_offset(channel => 'CHANnel2', offset => $a/2);
      $keysight->channel_range(channel => 'CHANnel2', range => $a*1.15);

      $keysight->trigger_level(channel => 'CHANnel1', level => $a/2);

      sleep(0.33);
      $rigol->output_toggle(channel => 1, value => 'ON');
      $rigol->output_toggle(channel => 2, value => 'ON');

      sleep(2);

      # Edit the file paths name since '-' and '.' are not allowed
      my $filename = "$folder\\Width$w"."s__Delay$d"."s__Amp$a"."Vpp";
      $filename =~ tr{-}{n};
      $filename =~ tr{.}{_};

      # Save each channels waveform and the measurements
      $keysight->save_waveform(source => 'CHANnel1', filename => "$filename"."__C1",format => 'CSV');
      $keysight->save_waveform(source => 'CHANnel2', filename => "$filename"."__C2",format => 'CSV');
      $keysight->save_measurements(filename => "$filename"."__MEAS");

      # Print the progress
      $c++;
      print $c,"/",$total,"\n";
      sleep(3);
    }
  }
}

### TO DO:
# phase align doesnt WORK -> coupling? -> PULSE doesnt support phase coupling...
# acquire_points doesnt work -> it kinda does?
# check if folder path exists and if not create it
# DONE: add measurements for error calculations
# DONE: replace - sign from filenames
