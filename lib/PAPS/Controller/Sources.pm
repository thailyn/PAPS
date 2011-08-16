package PAPS::Controller::Sources;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::Sources - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::Sources in Sources.');
}

=head2 base

=cut

sub base :Chained('/') :PathPart('sources') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store in the stash ResultSets that are useful to chained actions.
    $c->stash(sources_rs => $c->model('DB::Source'));
}

sub source :Chained('base') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $source_id) = @_;

    my $source = $c->stash->{sources_rs}->find({ id => $source_id },
                                             { key => 'primary' });

    die "No such source" if (!$source);

    $c->stash(source_id => $source_id);
    $c->stash(source => $source);
}



=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
