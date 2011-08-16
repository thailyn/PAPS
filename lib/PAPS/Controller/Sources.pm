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


=head2 details

Show the details for a specific source.

=cut

sub details :Chained('source') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $source_id = $c->stash->{source_id};

    my $matching_source = $c->stash->{sources_rs}
        ->find({id => {'=', $source_id}});

    $c->stash(source => $matching_source);

    $c->stash(template => 'sources/details.tt2');
}


=head2 list

Fetch all source objects and pass to sources/list.tt2 in stash to be displayed

=cut

sub list :Local {
    my ($self, $c) = @_;

    # Retrieve all of the source records as source model objects and store in the
    # stash where they can be accessed by the TT template
    $c->stash(sources => [$c->model('DB::Source')->all]);

    # Set the TT template to use.
    $c->stash(template => 'sources/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
