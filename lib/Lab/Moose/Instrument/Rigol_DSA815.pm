package Lab::Moose::Instrument::Rigol_DSA815;

#ABSTRACT: Rigol DSA815 Spectrum Analyzer

use 5.010;

use PDL::Core qw/pdl cat nelem/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_setter
    validated_channel_getter
    validated_channel_setter
    /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with 'Lab::Moose::Instrument::SpectrumAnalyzer',  qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Sense::Bandwidth
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Display::Window
    Lab::Moose::Instrument::SCPI::Unit

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::SCPIBlock

);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

=head1 SYNOPSIS

 my $data = $fsv->get_spectrum(timeout => 10);

=cut

=head1 METHODS

This driver implements the following high-level method:

=head2 get_spectrum

 $data = $fsv->get_spectrum(timeout => 10, trace => 2, precision => 'double');

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [freq1,  freq2,  freq3,  ...,  freqN],
  [power1, power2, power3, ..., powerN],
 ]

I.e. the first dimension runs over the sweep points.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace (1..6). Defaults to 1.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=cut

### Sense:Sweep:Points emulation
# Rigol DSA815 has no Sense:Sweep:Points implementation
my $hardwired_number_points_in_sweep = 601; # hardwired number of points in sweep

sub sense_sweep_points_query {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    return $self->cached_sense_sweep_points($hardwired_number_points_in_sweep);    # hard wired
    #return $self->cached_sense_sweep_points( nelem($self->get_traceY()) );    # hard wired
}

sub sense_sweep_points {
    # this hardware has not implemented command to set it in hardware
    # so we just updating the cache
    my ( $self, $channel, $value, %args ) = validated_channel_setter( \@_ );

    if ( $value != $hardwired_number_points_in_sweep ) {
        croak "This instrument allows in sweep number of points equal to $hardwired_number_points_in_sweep";
	$value = $hardwired_number_points_in_sweep;
    }

    $self->cached_sense_sweep_points($value);
}


### Trace acquisition implementation
sub get_traceY {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        precision_param(),
        trace => { isa => 'Int', default => 1 },
    );

    my $precision = delete $args{precision};

    my $trace = delete $args{trace};

    if ( $trace < 1 || $trace > 3 ) {
        croak "trace has to be in (1..3)";
    }

    # Ensure single sweep mode.
    if ( $self->cached_initiate_continuous() ) {
	$self->initiate_continuous( value => 0 );
    }

    # Ensure correct data format
    $self->set_data_format_precision( precision => $precision );

    # Get data.
    $self->write( command => ":FORMat:TRACe:DATA REAL,32");
    #$self->write( command => ":FORMat:TRACe:DATA ASCII");
    $self->initiate_immediate();
    $self->wai();
    my $binary = $self->binary_query(
        command => "TRAC? TRACE$trace",
        %args
    );
    my $points_ref = pdl $self->block_to_array(
        binary    => $binary,
        precision => $precision
    );
}

sub get_spectrum {
    my ( $self, %args ) = @_;

    my $traceY = $self->get_traceY( %args );
    #$self->sense_sweep_points( value => nelem($traceY) );
    my $traceX = $self->sense_frequency_linear_array();

    return cat( ( pdl $traceX), $traceY );
}

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Format>

=item L<Lab::Moose::Instrument::SCPI::Sense::Bandwidth>

=item L<Lab::Moose::Instrument::SCPI::Sense::Frequency>

=item L<Lab::Moose::Instrument::SCPI::Sense::Sweep>

=item L<Lab::Moose::Instrument::SCPI::Initiate>

=item L<Lab::Moose::Instrument::SCPIBlock>

=back

=cut


__PACKAGE__->meta()->make_immutable();

1;
