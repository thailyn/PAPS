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

sub base :Chained('/') :PathPart('sourcecategorytypes') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store in the stash ResultSets that are useful to chained actions.
    $c->stash(sources_rs => $c->model('DB::Source'));
    $c->stash(source_category_types_rs => $c->model('DB::SourceCategoryType'));
}

=head2 source_category_type

Captures an argument indicating a specific source_category_type_id to deal with.
If the referenced source category type exists, it and its
source_category_type_id  are stored in the stash.  If the source category type
does not exist, the method dies.

=cut

sub source_category_type :Chained('base'): PathPart('') :CaptureArgs(1) {
    my ($self, $c, $source_category_type_id) = @_;

    my $source_category_type = $c->stash->{source_category_types_rs}->find({ id => $source_category_type_id },
                                                                           { key => 'primary' });

    die "No such source category type" if (!$source_category_type);

    $c->stash(source_category_type_id => $source_category_type_id);
    $c->stash(source_category_type => $source_category_type);
}

=head2 details

Show the details for a specific source category type.

=cut

sub details :Chained('source_category_type') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $source_category_type_id = $c->stash->{source_category_type_id};

    my $matching_source_category_type = $c->model('DB::SourceCategoryType')
        ->find({id => {'=', $source_category_type_id}});

    #$c->stash(work_id => $requested_work);
    $c->stash(source_category_type => $matching_source_category_type);

    $c->stash(template => 'source_category_types/details.tt2');
}

=head2 edit_form

=cut

sub edit_form :Chained('base') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve all of the Reference records as WorkReference model objects and
    # store in the stash where they can be accessed by the TT template
    $c->stash(source_category_types => [$c->model('DB::SourceCategoryType')
                                        ->search(undef, { order_by => { -asc => [qw/source_id name/] }, })
                                        ->all]);

    # Set the TT template to use
    $c->stash(template => 'source_category_types/edit.tt2');
}

=head2 do_edit

This method is virtually identical to do_edit_reference in the References
controller.  Figure out which to keep and get rid of one, so we do not
duplicate code.

=cut

sub do_edit :Chained('base') :PathPart('do_edit') :Args(1) {
    my ($self, $c, $source_category_type_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_category_type = $c->model('DB::SourceCategoryType')->find({id => {'=', $source_category_type_id}});

    if (lc $params->{submit} eq 'edit') {
        $source_category_type->update({
            name => $params->{name} || undef,
            description => $params->{description} || undef,
            source_id => $params->{source_id} || undef,
                           });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('sourcecategorytypes')->action_for('edit_form'),
                    [ ]));
}

=head2 create_form

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'source_category_types/new.tt2');
}


=head2 do_create

Take information from form and add to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    my $params = $c->request->params;

    # Create the source category type
    my $source_category_type = $c->model('DB::SourceCategoryType')->create({
        name => $params->{name},
        description => $params->{description} || undef,
        source_id => $params->{source_id} || undef,
                                                 });

    # Store new model object in stash and set template
    $c->stash(source_category_type => $source_category_type,
              template => 'source_category_types/create_done.tt2');
}

=head2 list

Fetch all source category type objects and pass to source_category_types/list.tt2
in stash to be displayed

=cut

sub list :Chained('base') :PathPart('list') :Args(0) {
    my ($self, $c) = @_;

    ## Retrieve all of the source category type records as source model objects
    ## and store in the stash where they can be accessed by the TT template
    $c->stash(source_category_types => [$c->model('DB::SourceCategoryType')->all]);

    # Set the TT template to use.
    $c->stash(template => 'source_category_types/list.tt2');
}

=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
