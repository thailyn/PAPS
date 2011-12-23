package PAPS::Controller::SourceCategoryTypes;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::SourceCategoryTypes - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::SourceCategoryTypes in SourceCategoryTypes.');
}

=head2 base

=cut

sub base :Chained('/') :PathPart('sourcecategories') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store in the stash ResultSets that are useful to chained actions.
    $c->stash(source_category_types_rs => $c->model('DB::SourceCategoryType'));
}

=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
