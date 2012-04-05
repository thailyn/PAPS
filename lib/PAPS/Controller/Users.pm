package PAPS::Controller::Users;
use Moose;
use namespace::autoclean;
use Data::Dumper;

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


=head2 edit_form

=cut

sub edit_form :Chained('user') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $user_id = $c->stash->{user_id};

    my $matching_user = $c->model('DB::User')
        ->find({id => {'=', $user_id}});

    $c->stash(user => $matching_user);

    # Set the TT template to use
    $c->stash(template => 'users/edit.tt2');
}


=head2 do_edit

Take information from form and update a work in the database.

=cut

sub do_edit :Chained('user') :PathPart('do_edit') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $user = $c->stash->{user};

    if (lc $params->{Submit} eq 'submit') {
        $user->update({
            name => $params->{name},
            #password_hash => $params->{password} || undef,
            first_name => $params->{first_name} || undef,
            middle_name => $params->{middle_name} || undef,
            last_name => $params->{last_name} || undef,
            email => $params->{email} || undef,
                      });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('Users')->action_for('details'),
                    [ $user->id ]));
}


=head2 create_form

=cut

sub create_form :Chained('base') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'users/new.tt2');
}


=head2 do_create

Take information from form and add to database

=cut

sub do_create :Chained('base') :PathPart('do_create') :Args(0) {
    my ($self, $c) = @_;

    # Retrieve the values from the form
    my $name = $c->request->params->{name};
    my $password = $c->request->params->{password};
    my $first_name = $c->request->params->{first_name} || undef;
    my $middle_name = $c->request->params->{middle_name} || undef;
    my $last_name = $c->request->params->{last_name} || undef;
    my $email = $c->request->params->{email} || undef;

    # Create the user
    my $user = $c->model('DB::User')->create({
            name => $name,
            password_hash => $password,
            first_name => $first_name,
            middle_name => $middle_name,
            last_name => $last_name,
            email => $email,
            is_active => 1,
        });

    #$c->log->debug("password_hash: " . Dumper($user->column_info('password_hash')));
    #$c->log->debug("date_created: " . Dumper($user->column_info('date_created')));

    # Store new model object in stash and set template
    $c->stash(user => $user,
              template => 'users/create_done.tt2');
}


=head2 do_edit_collection

TODO: Describe me.

=cut

sub do_edit_collection :Chained('user') :PathPart('do_edit_collection') :Args(1) {
    my ($self, $c, $collection_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $user = $c->stash->{user};
    # Get the user's collections with the has-many relationship.
    my $collection = $user->collections->find({id => {'=', $collection_id}});

    if (lc $params->{submit} eq 'save') {
        $collection->update({
            name => $params->{name} || undef,
            description => $params->{description} || undef,
            #created_timestamp => $params->{created_timestamp} || undef,
            show_with_works => $params->{show_with_works} || 0,
            show_with_work_references => $params->{show_with_work_references} || 0,
            show_with_referenced_works => $params->{show_with_referenced_works} || 0,
                            });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('users')->action_for('edit_form'),
                    [ $user->id ]));
}

=head2 do_add_collection

TODO: Describe me.

=cut

sub do_add_collection :Chained('user') :PathPart('do_add_collection') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $user = $c->stash->{user};

    if (lc $params->{submit} eq 'add') {
        $user->create_related('collections', {
            name => $params->{name} || undef,
            description => $params->{description} || undef,
            #created_timestamp => $params->{created_timestamp} || undef,
            show_with_works => $params->{show_with_works} || 0,
            show_with_work_references => $params->{show_with_work_references} || 0,
            show_with_referenced_works => $params->{show_with_referenced_works} || 0,
                              });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('users')->action_for('edit_form'),
                    [ $user->id ]));
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

=head2 login

TODO: Describe me.

=cut

sub login :Chained('base') :PathPart('login') :Args(0) {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash(template => 'users/login.tt2');
}

=head2 do_login

TODO: Describe me.

=cut

sub do_login :Chained('base') :PathPart('do_login') :Args(0) {
    my ($self, $c) = @_;

    my $user = $c->req->params->{'name'};
    my $password = $c->req->params->{'password'};

    $c->log->debug("*** Starting login process.");

    if (lc $c->req->params->{'Submit'} eq 'submit') {
        if (defined $user) {
            if ($c->authenticate(
                    {
                        name => $user,
                        password_hash => $password
                    })) {
                $c->log->debug("*** User $user is now logged in with password $password.");
            }
            else {
                $c->log->debug("*** User $user failed to login with password $password.");
            }
        }
        else {
            $c->log->debug("*** No supplied user name.");
        }
    }
    else {
        $c->log->debug("*** Login cancelled.");
    }
    #$c->response->redirect(
    #    $c->uri_for($c->controller('Users')->action_for('list')));
    #$c->detach();
    #return;

    $c->stash(template => 'users/do_login.tt2');
}

=head2 logout

TODO: Describe me.

=cut

sub logout :Chained('base') :PathPart('logout') :Args(0) {
    my ($self, $c) = @_;

    $c->logout;

    $c->stash(template => 'users/logout.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
