package PAPS::Controller::Works;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::Works - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Chained('/') :PathPart('works') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store the ResultSet in stash so it's available for other methods
    $c->stash(resultset => $c->model('DB::Work'));

    ## Print a message to the debug log
    #$c->log->debug('*** INSIDE BASE METHOD ***');
}

=head2 details

Show the details for a specific work.

=cut

sub details :Chained('base') :PathPart('') :Args(1) {
    my ($self, $c, $requested_work_id) = @_;

    my $matching_work = $c->model('DB::Work')
        ->find({work_id => {'=', $requested_work_id}});

    $c->stash(work_id => $requested_work_id);
    $c->stash(requested_work => $matching_work);

    # Retrieve all of the work records as work model objects and store in the
    # stash where they can be accessed by the TT template
    #$c->stash(works => [$c->model('DB::Work')->all]);

    #  If the find method does not get any matching records, a defined
    # but false value is returned.  We can customize which template used
    # based on this value.
    #if ($matching_work) {
    #    # Use template that shows work details
    #}
    #else {
    #    # Use template that is specialized for finding no results
    #}


    $c->stash(template => 'works/details.tt2');
}


=head2 create_form

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'works/new.tt2');
}


=head2 do_create

Take information from form and add to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve the values from the form
    my $title = $c->request->params->{title};
    my $subtitle = $c->request->params->{subtitle} || undef;
    my $doi = $c->request->params->{doi} || undef;
    my $work_type_id = $c->request->params->{work_type_id} || '2';
    #my $author_id = $c->request->params->{author_id} || '1';

    # Create the work
    my $work = $c->model('DB::Work')->create({
            title   => $title,
            subtitle => $subtitle,
            doi => $doi,
            work_type_id => $work_type_id,
        });
    # Handle relationship with author
    #$work->add_to_work_authors({author_id => $author_id});
    # Note: Above is a shortcut for this:
    # $work->create_related('work_authors', {author_id => $author_id});

    # Store new model object in stash and set template
    $c->stash(work => $work,
              template => 'works/create_done.tt2');
}


=head2 list

Fetch all work objects and pass to works/list.tt2 in stash to be displayed

=cut

sub list :Local {
    my ($self, $c) = @_;

    # Retrieve all of the work records as work model objects and store in the
    # stash where they can be accessed by the TT template
    $c->stash(works => [$c->model('DB::Work')->all]);

    # Set the TT template to use.
    $c->stash(template => 'works/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
