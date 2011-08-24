package PAPS::Controller::References;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::References - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::References in References.');
}


=head2 base

=cut

sub base :Chained('/') :PathPart('references') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store ResultSet in the so they are available for other methods.
    $c->stash(works_rs => $c->model('DB::Work'));
    $c->stash(work_types_rs => $c->model('DB::WorkType'));
    $c->stash(reference_types_rs => $c->model('DB::ReferenceType'));
    #$c->stash(people_rs => $c->model('DB::People'));
    #$c->stash(sources_rs => $c->model('DB::Source'));
}


=head2 edit_form

=cut

sub edit_form :Chained('base') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve all of the Reference records as WorkReference model objects and
    # store in the stash where they can be accessed by the TT template
    $c->stash(references => [$c->model('DB::WorkReference')
                             ->search(undef, { order_by => { -asc => [qw/referencing_work_id chapter rank/] }, })
                             ->all]);

    # Set the TT template to use
    $c->stash(template => 'references/edit.tt2');
}

=head2 do_edit

This method is virtually identical to do_edit_reference in the Works
controller.  Figure out which to keep and get rid of one, so we do not
duplicate code.

=cut

sub do_edit :Chained('base') :PathPart('do_edit') :Args(1) {
    my ($self, $c, $reference_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $reference = $c->model('DB::WorkReference')->find({id => {'=', $reference_id}});

    if (lc $params->{submit} eq 'edit') {
        $reference->update({
            referencing_work_id => $params->{referencing_work_id} || undef,
            rank => $params->{rank} || undef,
            chapter => $params->{chapter} || undef,
            reference_type_id => $params->{reference_type_id} || undef,
            referenced_work_id => $params->{referenced_work_id} || undef,
            reference_text => $params->{reference_text} || undef,
                           });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('references')->action_for('edit_form'),
                    [ ]));
}


=head2 list

Fetch all Reference objects and pass to references/list.tt2 in the stash to be displayed

=cut

sub list :Local {
    my ($self, $c) = @_;

    # Retrieve all of the Reference records as WorkReference model objects and
    # store in the stash where they can be accessed by the TT template
    $c->stash(references => [$c->model('DB::WorkReference')
                             ->search(undef, { order_by => { -asc => [qw/referencing_work_id chapter rank/] }, })
                             ->all]);

    # Set the TT template to use.
    $c->stash(template => 'references/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
