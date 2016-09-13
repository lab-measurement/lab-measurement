package Lab::MooseInstrument::SCPI::Sense::Frequency;

use Moose::Role;
use Lab::MooseInstrument::Cache;
use Lab::MooseInstrument qw/validated_channel_getter validated_channel_setter/;
use MooseX::Params::Validate;
use Carp;

use namespace::autoclean;

with 'Lab::MooseInstrument::SCPI::Sense::Sweep';

cache sense_frequency_start => ( getter => 'sense_frequency_start_query' );

sub sense_frequency_start_query {
    my ( $self, $channel, %args ) = validated_channel_getter(@_);

    return $self->cached_sense_frequency_start(
        $self->query( command => 'SENS%s:FREQ:STAR?', $channel, %args ) );
}

sub sense_frequency_start {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(@_);
    $self->write(
        command => sprintf( "SENS%s:FREQ:STAR %g", $channel, $value ),
        %args
    );
    $self->cached_sense_frequency_start($value);
}

cache sense_frequency_stop => ( getter => 'sense_frequency_stop_query' );

sub sense_frequency_stop_query {
    my ( $self, $channel, %args ) = validated_channel_getter(@_);

    return $self->cached_sense_frequency_stop(
        $self->query( command => 'SENS%s:FREQ:STOP?', $channel, %args ) );
}

sub sense_frequency_stop {
    my ( $self, $channel, $value, %args ) = validated_channel_setter(@_);
    $self->write(
        command => sprintf( "SENS%s:FREQ:STOP %g", $channel, $value ),
        %args
    );
    $self->cached_sense_frequency_stop($value);
}

sub sense_frequency_linear_array {
    my ( $self, $channel, %args ) = validated_channel_getter(@_);

    my $start      = $self->cached_sense_frequency_start();
    my $stop       = $self->cached_sense_frequency_stop();
    my $num_points = $self->cached_sense_sweep_points();

    my $num_intervals = $num_points - 1;

    if ( $num_intervals < 1 ) {
        croak "non positive number of intervals";
    }

    my @result;

    for my $i ( 0 .. $num_intervals ) {
        my $f = $start + ( $stop - $start ) * ( $i / $num_intervals );
        push @result, $f;
    }

    return \@result;
}

1;