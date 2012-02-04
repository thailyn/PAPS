package PAPS::Controller::Users;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

PAPS::Controller::Users - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched PAPS::Controller::Users in Users.');
}

=head2 base

Can place common logic to start chained dispatch here

=cut

sub base :Chained('/') :PathPart('users') :CaptureArgs(0) {
    my ($self, $c) = @_;

    # Store the ResultSet in stash so it's available for other methods
    $c->stash(users_rs => $c->model('DB::User'));

    ## Print a message to the debug log
    #$c->log->debug('*** INSIDE BASE USERS METHOD ***');
}

=head2 user

Captures an argument indicating a specific user_id to deal with.  If the
referenced user exists, it and its user_id are stored in the stash.  If the
user does not exist, the method dies.

=cut

sub user :Chained('base'): PathPart('') :CaptureArgs(1) {
    my ($self, $c, $user_id) = @_;

    my $user = $c->stash->{users_rs}->find({ id => $user_id },
                                           { key => 'primary' });

    die "No such user" unless ($user);

    $c->stash(user_id => $user_id);
    $c->stash(user => $user);
}

=head2 details

Show the details for a specific user.

=cut

sub details :Chained('user') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $user_id = $c->stash->{user_id};

    my $matching_user = $c->model('DB::User')
        ->find({id => {'=', $user_id}});

    $c->stash(requested_user => $matching_user);

    $c->stash(template => 'users/details.tt2');
}

=head2 list

Fetch all user objects and pass to users/list.tt2 in stash to be displayed

=cut

sub list :Local {
    my ($self, $c) = @_;

    # Retrieve all of the user records as user model objects and store in the
    # stash where they can be accessed by the TT template
    $c->stash(users => [$c->model('DB::User')->all]);

    # Set the TT template to use.
    $c->stash(template => 'users/list.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
