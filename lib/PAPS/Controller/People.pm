package PAPS::Controller::People;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::People - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Chained('/') :PathPart('people') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store the ResultSet in stash so it's available for other methods
    $c->stash(resultset => $c->model('DB::People'));

    ## Print a message to the debug log
    #$c->log->debug('*** INSIDE PEOPLE BASE METHOD ***');
}


=head2 details

Show the details for a specific person.

=cut

sub details :Chained('base') :PathPart('') :Args(1) {
    my ($self, $c, $requested_person_id) = @_;

    my $matching_person = $c->model('DB::People')
        ->find({person_id => {'=', $requested_person_id}});

    $c->stash(person_id => $requested_person_id);
    $c->stash(requested_person => $matching_person);

    # This does not work as well as I hoped.  This only gets the first work
    # for a person, and is not needed, due to the works relationship, and the
    # work_type relationship off of that.
    #if ($matching_person) {
    #    my @works = $c->model('DB::Works')
    #        ->search({'work_authors.person_id' => $requested_person_id},
    #                 {
    #                     join => [ 'work_authors', 'work_type_id' ],
    #                     #'+select' => 'work_type_id.work_type',
    #                     #'+as' => 'work_type_name',
    #                 },
    #        );
    #    $c->stash(person_works => @works);
    #}

    #  If the find method does not get any matching records, a defined
    # but false value is returned.  We can customize which template used
    # based on this value.
    #if ($matching_person) {
    #    # Use template that shows work details
    #}
    #else {
    #    # Use template that is specialized for finding no results
    #}

    $c->stash(template => 'people/details.tt2');
}


=head2 create_form

Present a form to create a new Person.

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'people/new.tt2');
}


=head2 do_create

Take information from form and add new Person to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve the values from the form
    my $first_name = $c->request->params->{first_name};
    my $middle_name = $c->request->params->{middle_name} || undef;
    my $last_name = $c->request->params->{last_name};

    # Create the work
    my $person = $c->model('DB::People')->create({
            first_name => $first_name,
            middle_name => $middle_name,
            last_name => $last_name,
        });
    # Below section taken from Works controller:
    # Handle relationship with author
    #$work->add_to_work_authors({author_id => $author_id});
    # Note: Above is a shortcut for this:
    # $work->create_related('work_authors', {author_id => $author_id});

    # Store new model object in stash and set template
    $c->stash(person => $person,
              template => 'people/create_done.tt2');
}



=head2 list

Fetch all people objects and pass to people/list.tt2 in stash to be displayed

=cut

sub list :Local {
    my ($self, $c) = @_;

    # Retrieve all of the people records as people model objects and store in the
    # stash where they can be accessed by the TT template
    $c->stash(people => [$c->model('DB::People')->all]);

    # Set the TT template to use.
    $c->stash(template => 'people/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
