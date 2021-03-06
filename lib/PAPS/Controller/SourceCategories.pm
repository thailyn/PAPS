package PAPS::Controller::SourceCategories;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::SourceCategories - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::SourceCategories in SourceCategories.');
}


=head2 base

=cut

sub base :Chained('/') :PathPart('sourcecategories') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store in the stash ResultSets that are useful to chained actions.
    $c->stash(sources_rs => $c->model('DB::Source'));
    $c->stash(source_categories_rs => $c->model('DB::SourceCategory'));
    $c->stash(source_category_types_rs => $c->model('DB::SourceCategoryType'));
}

=head2 source_category

Captures an argument indicating a specific source_category_id to deal with.
If the referenced source category exists, it and its source_category_id are
stored in the stash.  If the source category does not exist, the method dies.

=cut

sub source_category :Chained('base'): PathPart('') :CaptureArgs(1) {
    my ($self, $c, $source_category_id) = @_;

    my $source_category = $c->stash->{source_categories_rs}->find({ id => $source_category_id },
                                                                  { key => 'primary' });

    die "No such source category" if (!$source_category);

    $c->stash(source_category_id => $source_category_id);
    $c->stash(source_category => $source_category);
}

=head2 details

Show the details for a specific source category.

=cut

sub details :Chained('source_category') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $source_category_id = $c->stash->{source_category_id};

    my $matching_source_category = $c->model('DB::SourceCategory')
        ->find({id => {'=', $source_category_id}});

    $c->stash(source_category => $matching_source_category);

    $c->stash(template => 'source_categories/details.tt2');
}

=head2 edit_form_single

=cut

sub edit_form_single :Chained('source_category') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $source_category_id = $c->stash->{source_category_id};

    my $matching_source_category = $c->model('DB::SourceCategory')
        ->find({id => {'=', $source_category_id}});

    $c->stash(source_category => $matching_source_category);

    # Set the TT template to use
    $c->stash(template => 'source_categories/edit_single.tt2');
}

=head2 do_edit_single

Take information from form and update a work in the database.

=cut

sub do_edit_single :Chained('source_category') :PathPart('do_edit') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_category = $c->stash->{source_category};

    # Retrieve the values from the form
    my $name = $params->{name};
    my $description = $params->{description} || undef;
    my $parent_category_id = $params->{parent_category_id} || undef;
    my $category_type_id = $params->{category_type_id} || undef;
    my $source_id = $params->{source_id} || undef;

    if (lc $params->{Submit} eq 'submit') {
        $source_category->update({
            name => $name,
            description => $description,
            parent_category_id => $parent_category_id,
            category_type_id => $category_type_id,
            source_id => $source_id,
                                      });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('SourceCategories')->action_for('details'),
                    [ $source_category->id ]));
}

=head2 edit_form

=cut

sub edit_form :Chained('base') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve all of the source category as SourceCategoryType model objects
    # and store in the stash where they can be accessed by the TT template
    $c->stash(source_categories => [$c->model('DB::SourceCategory')
                                    ->search(undef, { order_by => { -asc => [qw/source_id category_type_id name/] }, })
                                    ->all]);

    # Set the TT template to use
    $c->stash(template => 'source_categories/edit.tt2');
}

=head2 do_edit

This method is virtually identical to do_edit_reference in the References
controller.  Figure out which to keep and get rid of one, so we do not
duplicate code.

=cut

sub do_edit :Chained('base') :PathPart('do_edit') :Args(1) {
    my ($self, $c, $source_category_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $source_category = $c->model('DB::SourceCategory')->find({id => {'=', $source_category_id}});

    if (lc $params->{submit} eq 'edit') {
        $source_category->update({
            name => $params->{name} || undef,
            description => $params->{description} || undef,
            parent_category_id => $params->{parent_category_id} || undef,
            category_type_id => $params->{category_type_id} || undef,
            source_id => $params->{source_id} || undef,
                                 });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('SourceCategories')->action_for('edit_form'),
                    [ ]));
}

=head2 create_form

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'source_categories/new.tt2');
}


=head2 do_create

Take information from form and add to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    my $params = $c->request->params;

    # Create the source category type
    my $source_category = $c->model('DB::SourceCategory')->create({
        name => $params->{name},
        description => $params->{description} || undef,
        parent_category_id => $params->{parent_category_id} || undef,
        category_type_id => $params->{category_type_id} || undef,
        source_id => $params->{source_id} || undef,
                                                                  });

    # Store new model object in stash and set template
    $c->stash(source_category => $source_category,
              template => 'source_categories/create_done.tt2');
}


=head2 list

Fetch all source category objects and pass to source_category/list.tt2
in stash to be displayed

=cut

sub list :Chained('base') :PathPart('list') :Args(0) {
    my ($self, $c) = @_;

    ## Retrieve all of the source category records as source model objects and
    ## store in the stash where they can be accessed by the TT template
    $c->stash(source_categories => [$c->model('DB::SourceCategory')->all]);

    # Set the TT template to use.
    $c->stash(template => 'source_categories/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
