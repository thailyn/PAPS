package PAPS::Controller::SourceTags;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::SourceTags - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::SourceTags in SourceTags.');
}

=head2 base

=cut

sub base :Chained('/') :PathPart('sourcetags') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store in the stash ResultSets that are useful to chained actions.
    $c->stash(sources_rs => $c->model('DB::Source'));
    $c->stash(source_tags_rs => $c->model('DB::SourceTag'));
    $c->stash(source_tag_types_rs => $c->model('DB::SourceTagType'));
}

=head2 source_tag

Captures an argument indicating a specific source_tag_id to deal with.
If the referenced source tag exists, it and its source_tag_id are
stored in the stash.  If the source tag does not exist, the method dies.

=cut

sub source_tag :Chained('base'): PathPart('') :CaptureArgs(1) {
    my ($self, $c, $source_tag_id) = @_;

    my $source_tag = $c->stash->{source_tags_rs}->find({ id => $source_tag_id },
                                                       { key => 'primary' });

    die "No such source tag" if (!$source_tag);

    $c->stash(source_tag_id => $source_tag_id);
    $c->stash(source_tag => $source_tag);
}

=head2 details

Show the details for a specific source tag.

=cut

sub details :Chained('source_tag') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $source_tag_id = $c->stash->{source_tag_id};

    my $matching_source_tag = $c->model('DB::SourceTag')
        ->find({id => {'=', $source_tag_id}});

    $c->stash(source_tag => $matching_source_tag);

    $c->stash(template => 'source_tags/details.tt2');
}

=head2 edit_form_single

=cut

sub edit_form_single :Chained('source_tag') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $source_tag_id = $c->stash->{source_tag_id};

    my $matching_source_tag = $c->model('DB::SourceTag')
        ->find({id => {'=', $source_tag_id}});

    $c->stash(source_tag => $matching_source_tag);

    # Set the TT template to use
    $c->stash(template => 'source_tags/edit_single.tt2');
}

=head2 do_edit_single

Take information from form and update a work in the database.

=cut

sub do_edit_single :Chained('source_tag') :PathPart('do_edit') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_tag = $c->stash->{source_tag};

    # Retrieve the values from the form
    my $name = $params->{name};
    my $description = $params->{description} || undef;
    my $tag_type_id = $params->{tag_type_id} || undef;
    my $source_id = $params->{source_id} || undef;

    if (lc $params->{Submit} eq 'submit') {
        $source_tag->update({
            name => $name,
            description => $description,
            tag_type_id => $tag_type_id,
            source_id => $source_id,
                            });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('SourceTags')->action_for('details'),
                    [ $source_tag->id ]));
}

=head2 edit_form

=cut

sub edit_form :Chained('base') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve all of the source tags as SourceTagType model objects
    # and store in the stash where they can be accessed by the TT template
    $c->stash(source_tags => [$c->model('DB::SourceTag')
                              ->search(undef, { order_by => { -asc => [qw/source_id tag_type_id name/] }, })
                              ->all]);

    # Set the TT template to use
    $c->stash(template => 'source_tags/edit.tt2');
}

=head2 do_edit

This method is virtually identical to do_edit_reference in the References
controller.  Figure out which to keep and get rid of one, so we do not
duplicate code.

=cut

sub do_edit :Chained('base') :PathPart('do_edit') :Args(1) {
    my ($self, $c, $source_tag_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_tag = $c->model('DB::SourceTag')->find({id => {'=', $source_tag_id}});

    if (lc $params->{submit} eq 'edit') {
        $source_tag->update({
            name => $params->{name} || undef,
            description => $params->{description} || undef,
            tag_type_id => $params->{tag_type_id} || undef,
            source_id => $params->{source_id} || undef,
                            });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('SourceTags')->action_for('edit_form'),
                    [ ]));
}

=head2 create_form

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'source_tags/new.tt2');
}


=head2 do_create

Take information from form and add to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    my $params = $c->request->params;

    # Create the source tag type
    my $source_tag = $c->model('DB::SourceTag')->create({
        name => $params->{name},
        description => $params->{description} || undef,
        tag_type_id => $params->{tag_type_id} || undef,
        source_id => $params->{source_id} || undef,
                                                        });

    # Store new model object in stash and set template
    $c->stash(source_tag => $source_tag,
              template => 'source_tags/create_done.tt2');
}


=head2 list

Fetch all source tag objects and pass to source_tags/list.tt2
in stash to be displayed

=cut

sub list :Chained('base') :PathPart('list') :Args(0) {
    my ($self, $c) = @_;

    ## Retrieve all of the source tag records as source model objects and
    ## store in the stash where they can be accessed by the TT template
    $c->stash(source_tags => [$c->model('DB::SourceTag')->all]);

    # Set the TT template to use.
    $c->stash(template => 'source_tags/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
