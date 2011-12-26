package PAPS::Controller::SourceTagTypes;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::SourceTagTypes - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::SourceTagTypes in SourceTagTypes.');
}

=head2 base

=cut

sub base :Chained('/') :PathPart('sourcetagtypes') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store in the stash ResultSets that are useful to chained actions.
    $c->stash(sources_rs => $c->model('DB::Source'));
    $c->stash(source_tag_types_rs => $c->model('DB::SourceTagType'));
}

=head2 source_tag_type

Captures an argument indicating a specific source_tag_type_id to deal with.
If the referenced source tag type exists, it and its source_tag_type_id are
stored in the stash.  If the source tag type does not exist, the method dies.

=cut

sub source_tag_type :Chained('base'): PathPart('') :CaptureArgs(1) {
    my ($self, $c, $source_tag_type_id) = @_;

    my $source_tag_type = $c->stash->{source_tag_types_rs}->find({ id => $source_tag_type_id },
                                                                 { key => 'primary' });

    die "No such source tag type" if (!$source_tag_type);

    $c->stash(source_tag_type_id => $source_tag_type_id);
    $c->stash(source_tag_type => $source_tag_type);
}

=head2 details

Show the details for a specific source tag type.

=cut

sub details :Chained('source_tag_type') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $source_tag_type_id = $c->stash->{source_tag_type_id};

    my $matching_source_tag_type = $c->model('DB::SourceTagType')
        ->find({id => {'=', $source_tag_type_id}});

    #$c->stash(work_id => $requested_work);
    $c->stash(source_tag_type => $matching_source_tag_type);

    $c->stash(template => 'source_tag_types/details.tt2');
}

=head2 edit_form_single

=cut

sub edit_form_single :Chained('source_tag_type') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $source_tag_type_id = $c->stash->{source_tag_type_id};

    my $matching_source_tag_type = $c->model('DB::SourceTagType')
        ->find({id => {'=', $source_tag_type_id}});

    #$c->stash(work_id => $requested_work_id);
    $c->stash(source_tag_type => $matching_source_tag_type);

    # Set the TT template to use
    $c->stash(template => 'source_tag_types/edit_single.tt2');
}

=head2 do_edit_single

Take information from form and update a work in the database.

=cut

sub do_edit_single :Chained('source_tag_type') :PathPart('do_edit') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_tag_type = $c->stash->{source_tag_type};

    # Retrieve the values from the form
    my $name = $params->{name};
    my $description = $params->{description} || undef;
    my $source_id = $params->{source_id} || undef;

    if (lc $params->{Submit} eq 'submit') {
        $source_tag_type->update({
            name => $name,
            description => $description,
            source_id => $source_id,
                                 });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('SourceTagTypes')->action_for('details'),
                    [ $source_tag_type->id ]));
}

=head2 edit_form

=cut

sub edit_form :Chained('base') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve all of the records as model objects and
    # store in the stash where they can be accessed by the TT template
    $c->stash(source_tag_types => [$c->model('DB::SourceTagType')
                                   ->search(undef, { order_by => { -asc => [qw/source_id name/] }, })
                                   ->all]);

    # Set the TT template to use
    $c->stash(template => 'source_tag_types/edit.tt2');
}

=head2 do_edit

This method is virtually identical to do_edit_reference in the References
controller.  Figure out which to keep and get rid of one, so we do not
duplicate code.

=cut

sub do_edit :Chained('base') :PathPart('do_edit') :Args(1) {
    my ($self, $c, $source_tag_type_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_tag_type = $c->model('DB::SourceTagType')->find({id => {'=', $source_tag_type_id}});

    if (lc $params->{submit} eq 'edit') {
        $source_tag_type->update({
            name => $params->{name} || undef,
            description => $params->{description} || undef,
            source_id => $params->{source_id} || undef,
                                 });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('SourceTagTypes')->action_for('edit_form'),
                    [ ]));
}

=head2 create_form

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'source_tag_types/new.tt2');
}


=head2 do_create

Take information from form and add to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    my $params = $c->request->params;

    # Create the source tag type
    my $source_tag_type = $c->model('DB::SourceTagType')->create({
        name => $params->{name},
        description => $params->{description} || undef,
        source_id => $params->{source_id} || undef,
                                                                 });

    # Store new model object in stash and set template
    $c->stash(source_tag_type => $source_tag_type,
              template => 'source_tag_types/create_done.tt2');
}

=head2 list

Fetch all source tag type objects and pass to source_tag_types/list.tt2
in stash to be displayed

=cut

sub list :Chained('base') :PathPart('list') :Args(0) {
    my ($self, $c) = @_;

    ## Retrieve all of the source tag type records as source model objects
    ## and store in the stash where they can be accessed by the TT template
    $c->stash(source_tag_types => [$c->model('DB::SourceTagType')->all]);

    # Set the TT template to use.
    $c->stash(template => 'source_tag_types/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
