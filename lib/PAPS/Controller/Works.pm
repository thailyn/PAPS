package PAPS::Controller::Works;
use Moose;
use namespace::autoclean;
use GraphViz;
use GraphViz2;
use File::Temp ();

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
    $c->stash(works_rs => $c->model('DB::Work'));
    $c->stash(work_types_rs => $c->model('DB::WorkType'));
    $c->stash(reference_types_rs => $c->model('DB::ReferenceType'));
    $c->stash(source_tags_rs => $c->model('DB::SourceTag'));
    $c->stash(source_categories_rs => $c->model('DB::SourceCategory'));
    $c->stash(people_rs => $c->model('DB::Person'));
    $c->stash(sources_rs => $c->model('DB::Source'));

    ## Print a message to the debug log
    #$c->log->debug('*** INSIDE BASE METHOD ***');
}

=head2 work

Captures an argument indicating a specific work_id to deal with.  If the
referenced work exists, it and its work_id are stored in the stash.  If the
work does not exist, the method dies.

=cut

sub work :Chained('base'): PathPart('') :CaptureArgs(1) {
    my ($self, $c, $work_id) = @_;

    my $work = $c->stash->{works_rs}->find({ work_id => $work_id },
                                            { key => 'primary' });

    die "No such work" if (!$work);

    $c->stash(work_id => $work_id);
    $c->stash(work => $work);

    if ($c->user_exists) {
        my $user_work_data = $c->user->user_work_datas
            ->find({work_id => {'=', $work_id}});
        $c->stash(user_work_data => $user_work_data);
    }
}

=head2 details

Show the details for a specific work.

=cut

sub details :Chained('work') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $work_id = $c->stash->{work_id};

    my $matching_work = $c->model('DB::Work')
        ->find({work_id => {'=', $work_id}});

    $c->stash(requested_work => $matching_work);

    my $graph_file_name = create_work_graph($c, $c->stash->{work});
    $c->stash(graph_file_name => $graph_file_name);

    my $reading_graph_file_name = create_work_reading_graph($c, $c->stash->{work});
    $c->stash(reading_graph_file_name => $reading_graph_file_name);

    my $work_connected_component_file_name =
        create_work_connected_component_graph($c, $c->stash->{work});
    $c->stash(work_connected_component_file_name => $work_connected_component_file_name);

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


=head2 edit_form

=cut

sub edit_form :Chained('work') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    my $work_id = $c->stash->{work_id};

    my $matching_work = $c->model('DB::Work')
        ->find({work_id => {'=', $work_id}});

    #$c->stash(work_id => $requested_work_id);
    $c->stash(work => $matching_work);

    # Set the TT template to use
    $c->stash(template => 'works/edit.tt2');
}


=head2 do_edit

Take information from form and update a work in the database.

=cut

sub do_edit :Chained('work') :PathPart('do_edit') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};

    # Retrieve the values from the form
    my $title = $params->{title};
    my $subtitle = $params->{subtitle} || undef;
    my $doi = $params->{doi} || undef;
    my $work_type_id = $params->{work_type_id};# || '2';
    #my $author_id = $c->request->params->{author_id} || '1';

    if (lc $params->{Submit} eq 'submit') {
        $work->update({
            title => $params->{title},
            subtitle => $params->{subtitle} || undef,
            edition => $params->{edition} || undef,
            year => $params->{year} || undef,
            num_references => $params->{num_references} || undef,
            doi => $params->{doi} || undef,
            work_type_id => $params->{work_type} || undef,
                      });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('details'),
                    [ $work->id ]));
}


=head2 do_edit_author

TODO: Describe me.

=cut

sub do_edit_author :Chained('work') :PathPart('do_edit_author') :Args(1) {
    my ($self, $c, $author_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};
    # Using the many-to-many relationship $work->authors returns the
    # set of People objects, which is not what we want.  Use the has-many
    # relationship instead.
    my $work_author = $work->work_authors->find({works_author_id => {'=', $author_id}});

    if (lc $params->{submit} eq 'save') {
        $work_author->update({
            person_id => $params->{person_id} || undef,
            author_position => $params->{author_position} || undef,
            author_name_text => $params->{author_name_text} || undef,
            author_affiliation_text => $params->{author_affiliation_text} || undef,
                             });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_add_author

TODO: Describe me.

=cut

sub do_add_author :Chained('work') :PathPart('do_add_author') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};

    if (lc $params->{submit} eq 'add') {
        $work->create_related('work_authors', {
            #work_id => $work->work_id,
            person_id => $params->{person_id} || undef,
            author_position => $params->{author_position} || undef,
            author_name_text => $params->{author_name_text} || undef,
            author_affiliation_text => $params->{author_affiliation_text} || undef,
                              });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_edit_reference

TODO: Describe me.

=cut

sub do_edit_reference :Chained('work') :PathPart('do_edit_reference') :Args(1) {
    my ($self, $c, $reference_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};
    # Using the many-to-many relationship $work->referenced_works returns the
    # set of Work objects, which is not what we want.  Use the has-many
    # relationship instead.
    my $reference = $work->work_references_referenced_works->find({id => {'=', $reference_id}});

    if (lc $params->{submit} eq 'edit') {
        $reference->update({
            rank => $params->{rank} || undef,
            chapter => $params->{chapter} || undef,
            reference_type_id => $params->{reference_type_id} || undef,
            referenced_work_id => $params->{referenced_work_id} || undef,
            reference_text => $params->{reference_text} || undef,
                           });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_add_reference

TODO: Describe me.

=cut

sub do_add_reference :Chained('work') :PathPart('do_add_reference') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};

    if (lc $params->{submit} eq 'add') {
        $work->create_related('work_references_referenced_works', {
            #referencing_work_id => $work->work_id,
            referenced_work_id => $params->{referenced_work_id} || undef,
            reference_type_id => $params->{reference_type_id} || 1,
            rank => $params->{rank} || undef,
            chapter => $params->{chapter} || undef,
            reference_text => $params->{reference_text} || undef,
                              });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_edit_source

TODO: Describe me.

=cut

sub do_edit_source :Chained('work') :PathPart('do_edit_source') :Args(1) {
    my ($self, $c, $work_source_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};
    # Using the many-to-many relationship $work->sources returns the set of
    # Source objects, which is not what we want.  Use the has-many
    # relationship instead.
    my $work_source = $work->work_sources->find({id => {'=', $work_source_id}});

    if (lc $params->{submit} eq 'save') {
        $work_source->update({
            source_id => $params->{source_id} || undef,
            url => $params->{url} || undef
                           });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_add_source

TODO: Describe me.

=cut

sub do_add_source :Chained('work') :PathPart('do_add_source') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};

    if (lc $params->{submit} eq 'add') {
        $work->create_related('work_sources', {
            #work_id => $work->work_id,
            source_id => $params->{source_id} || undef,
            url => $params->{url} || undef,
                              });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}

=head2 do_edit_source_category

TODO: Describe me.

=cut

sub do_edit_source_category :Chained('work') :PathPart('do_edit_source_category') :Args(1) {
    my ($self, $c, $work_source_category_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};
    # Using the many-to-many relationship returns the set of
    # SourceCategory objects, which is not what we want.  Use the has-many
    # relationship instead.
    my $work_source_category = $work->source_work_categories->find({category_id => {'=', $work_source_category_id}});

    if (lc $params->{submit} eq 'edit') {
        $work_source_category->update({
            category_id => $params->{source_category_id} || undef,
            rank => $params->{category_rank} || undef,
                                      });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_add_source_category

TODO: Describe me.

=cut

sub do_add_source_category :Chained('work') :PathPart('do_add_source_category') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};

    if (lc $params->{submit} eq 'add') {
        $work->create_related('source_work_categories', {
            #work_id => $work->work_id,
            category_id => $params->{source_category_id} || undef,
            rank => $params->{category_rank} || undef,
                              });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}

=head2 do_edit_source_tag

TODO: Describe me.

=cut

sub do_edit_source_tag :Chained('work') :PathPart('do_edit_source_tag') :Args(1) {
    my ($self, $c, $work_source_tag_id) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};
    # Using the many-to-many relationship returns the set of
    # SourceTag objects, which is not what we want.  Use the has-many
    # relationship instead.
    my $work_source_tag = $work->source_work_tags->find({tag_id => {'=', $work_source_tag_id}});

    # This does not work, as source_tag_id is part of the primary key, and,
    # apparently, DBIx does not want to update those values.
    if (lc $params->{submit} eq 'save') {
        $work_source_tag->update({
            tag_id => $params->{source_tag_id} || undef,
                                 });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_add_source_tag

TODO: Describe me.

=cut

sub do_add_source_tag :Chained('work') :PathPart('do_add_source_tag') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};

    if (lc $params->{submit} eq 'add') {
        $work->create_related('source_work_tags', {
            #work_id => $work->work_id,
            tag_id => $params->{source_tag_id} || undef,
                              });
    }

    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
}


=head2 do_edit_user_data

TODO: Describe me.

=cut

sub do_edit_user_data :Chained('work') :PathPart('do_edit_user_data') :Args(0) {
    my ($self, $c) = @_;

    if (lc $c->request->method ne 'post') {
        return;
    }

    my $params = $c->request->params;
    my $work = $c->stash->{work};
    my $user_work_data = $c->stash->{'user_work_data'};

    my $read_timestamp = $params->{'read_timestamp'};
    $c->log->debug("*** Initial read_timestamp value: " . ($read_timestamp or "undef"));
    $read_timestamp = undef unless $params->{'read'};
    if (!$params->{'read_timestamp'} && $params->{'read'}) {
        $read_timestamp = "now";
    }
    $c->log->debug("*** Final read_timestamp value: " . ($read_timestamp or "undef"));

    if (lc $params->{submit} eq 'save user info') {
        $c->log->debug("*** In update block.");
        if ($user_work_data) {
            $c->log->debug("*** Going to update.");
            $user_work_data->update({
                read_timestamp => $read_timestamp || undef,
                understood_rating => $params->{'understood_rating'} || undef,
                approval_rating => $params->{'approval_rating'} || undef,
                                    });
        }
        else {
            $c->log->debug("*** Going to create.");
            $user_work_data = $c->user->create_related('user_work_datas', {
                work_id => $work->work_id,
                read_timestamp => $read_timestamp || undef,
                understood_rating => $params->{'understood_rating'} || undef,
                approval_rating => $params->{'approval_rating'} || undef,
                                                       });
        }
    }

    $c->log->debug("*** Redirecting.");
    return $c->res->redirect(
        $c->uri_for($c->controller('works')->action_for('edit_form'),
                    [ $work->id ]));
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


=head2 graph

TODO: Describe me

=cut

sub graph :Chained('base') :PathPart('graph') :Args(0) {
    my ($self, $c) = @_;

    my $g = GraphViz->new(
        directed => 0,
        layout => 'sfdp',
        overlap => 'scalexy', # 'false' works well but makes a big graph
        random_start => 'true'
        );
    my $works_rs = $c->stash->{works_rs};

    while (my $work = $works_rs->next) {
        #$c->log->debug($work->display_name);
        my ($outline_color, $fill_color, $node_style, $node_label);
        if (!$work->num_references) {
            $outline_color = 'red';
            $node_style = 'filled';
            $fill_color = 'gray';
        }
        elsif ($work->num_references != $c->model('DB::WorkReference')->search({ referencing_work_id => $work->work_id})->count) {
            $outline_color = 'yellow';
            $node_style = 'filled';
            $fill_color = 'gray';
        }
        else {
            $outline_color = 'black';
            $node_style = 'filled';
            $fill_color = 'gray';
        }

        $node_label = $work->display_name;
        $node_label .= " (" . $work->year . ")" if $work->year;

        $g->add_node($work->work_id, label => $node_label,
                     shape => 'record', style => $node_style,
                     color => $outline_color, fillcolor => $fill_color);
    }

    # get the list of references
    my $ref_rs = $c->model('DB::WorkReference')->search(undef,
                                                        { order_by => 'referencing_work_id'});

    # Create edges for references, either by creating an  edge between two
    # existing works, or creating a node for the referenced work that does not
    # exist and creating an edge to that.
    my $ref_work_id = -1;
    my $ref_num = 0;
    while (my $ref = $ref_rs->next) {
        # keep track of what number reference this is for a work, so we can
        # index each reference that does not have a referenced_work_id with a
        # number.
        if ($ref->referencing_work_id != $ref_work_id) {
            $ref_work_id = $ref->referencing_work_id;
            $ref_num = 0;
        }

        #$c->log->debug($ref->id . "\t" . $ref->referencing_work_id . "\t" .
        #               ($ref->referenced_work_id || "NULL") . "\t" . $ref->reference_type_id . "\t" .
        #               $ref->rank . "\t" . ($ref->chapter || "NULL") . "\t" . ($ref->reference_text || "NULL"));

        if ($ref->referenced_work_id) {
            # if the referenced work exists, simply create an edge between them
            $g->add_edge($ref->referencing_work_id => $ref->referenced_work_id, dir => 'forward');
        }
        else {
            # if the referenced work does not exist, create a new node an an
            # edge to it
            my $node_name = $ref->referencing_work_id . "-" . $ref_num;

            # some of the reference_text values throw an error when used as the
            # node name or able, so leave that out until we can scrub the text
            # properly
            $g->add_node($node_name, label => $node_name, shape => 'record', style => 'dotted'); # label => $ref->reference_text,
            $g->add_edge($ref->referencing_work_id => $node_name, dir => 'forward');
        }
        $ref_num++;
    }

    #$c->log->debug("*** DEBUG *** Home path: " . $c->config->{home});
    #$c->log->debug("*** DEBUG *** Sample path: " . $c->path_to('root', 'static', 'images', 'works.png'));

    # export the graph
    my $output_file_name = 'works.png';
    $g->as_png($c->path_to('root', 'static', 'images', $output_file_name)->stringify);

    $c->stash(graph_file_name => $output_file_name);
    $c->stash(template => 'works/graph.tt2');
}


=head2 graph2

TODO: Describe me

=cut

sub graph2 :Chained('base') :PathPart('graph2') :Args(0) {
    my ($self, $c) = @_;

    my $works_rs = $c->stash->{works_rs};
    if ($c->user_exists) {
      $works_rs = $works_rs->search(
            {
                -or => [
                     'user_work_datas.user_id' => $c->user->id,
                     'user_work_datas.user_id' => undef,
                    ]
            },
            {
                join => [ 'user_work_datas', 'work_references_referencing_works' ],
                prefetch => 'user_work_datas',
                '+select' => [ 'user_work_datas.read_timestamp',
                               'user_work_datas.understood_rating',
                               'user_work_datas.approval_rating',
                               'work_references_referencing_works.referencing_work_id' ],
                '+as' => [ 'read_timestamp',
                           'understood_rating',
                           'approval_rating',
                           'referencing_work_id' ],
            }
            );
    }

    my ($node_counts, $node_references_counts)
        = determine_node_counts_and_reference_counts($c, $works_rs);
    my @work_ids = keys %$node_counts;

    my $settings = { 'file_name' => 'works' };
    $settings->{'nodes'} = { };
    determine_work_custom_fill_colors($c, $settings, $node_counts, $node_references_counts);

    # get the list of references
    my $ref_rs = $c->model('DB::WorkReference')->search(undef,
                                                        { order_by => 'referencing_work_id'});

    my $graph_file_name = create_graph(undef, $c, $works_rs, $ref_rs, $settings);

    $c->stash(graph_file_name => $graph_file_name);
    $c->stash(template => 'works/graph.tt2');
    return;
}

=head2 graph_work

TODO: Describe me

=cut

sub graph_work :Chained('work') :PathPart('graph2') :Args(0) {
    my ($self, $c) = @_;

    #my $work_id = $c->stash->{work_id};
    my $work = $c->stash->{work};

    my $output_file_name = create_work_graph($c, $work);

    $c->stash(graph_file_name => $output_file_name);
    $c->stash(template => 'works/graph.tt2');
}

=head2 create_work_graph

Given the Catalyst object and a DB::Work object, create a graph of the work's
references.  Save it to a file and return the file name.

=cut

sub create_work_graph {
    my ($c, $work) = @_;
    my $work_id = $work->id;
    my $works_rs;

    # If a user is logged in, replace the work with a new instance of the work
    # that also has the user's data.  This search here can be optimized by
    # only (always) having the work id passed in instead of a work.
    $work_id = $work->id;
    if ($c->user_exists) {
        $works_rs = $c->model('DB::Work')
            ->search(
            {
                -and => [
                     -or => [
                          'me.work_id' => {'=', $work_id},
                          'work_references_referencing_works.referencing_work_id' => {'=', $work_id},
                          'work_references_referenced_works.referenced_work_id' => {'=', $work_id},
                     ],
                     -or => [
                          'user_work_datas.user_id' => $c->user->id,
                          'user_work_datas.user_id' => undef,
                     ],
                    ],
            },
            {
                join => [qw/ user_work_datas work_references_referenced_works work_references_referencing_works /],
                '+select' => [ 'user_work_datas.read_timestamp', 'user_work_datas.understood_rating', 'user_work_datas.approval_rating' ],
                '+as' => [ 'uwd_read_timestamp', 'uwd_understood_rating', 'uwd_approval_rating' ],
            });
    }
    else {
        $works_rs = $c->model('DB::Work')
            ->search(
            {
                -or => [
                     'me.work_id' => {'=', $work_id},
                     'work_references_referencing_works.referencing_work_id' => {'=', $work_id},
                     'work_references_referenced_works.referenced_work_id' => {'=', $work_id},
                    ],
            },
            {
                join => [qw/ work_references_referenced_works work_references_referencing_works /],
            });
    }

    my $ref_rs = $c->model('DB::WorkReference')
        ->search(
        {
            -or => [
                 'referenced_work_id' => {'=', $work_id},
                 'referencing_work_id' => {'=', $work_id},
                ],
        }, { });

    my $settings = { 'file_name' => 'work' . $work_id };
    my $output_file_name = create_graph(undef, $c, $works_rs, $ref_rs, $settings);

    return $output_file_name;
}

=head2 create_work_reading_graph

TODO: Describe me (similar to create_work_graph).

=cut

sub create_work_reading_graph {
    my ($c, $work) = @_;
    my $work_id = $work->id;
    my $works_rs;

    # If a user is logged in, replace the work with a new instance of the work
    # that also has the user's data.  This search here can be optimized by
    # only (always) having the work id passed in instead of a work.
    $work_id = $work->id;
    if ($c->user_exists) {
        $works_rs = $c->model('DB::WorkToRead')
            ->search({ },
                     {
                         bind => [ $work_id, $c->user->id ],
                     });
    }
    else {
        $works_rs = $c->model('DB::WorkToRead')
            ->search({ },
                     {
                         bind => [ $work_id, undef ],
                     });
    }

    my ($node_counts, $node_references_counts)
        = determine_node_counts_and_reference_counts($c, $works_rs);
    my @work_ids = keys %$node_counts;

    my $settings = { 'file_name' => 'work' . $work_id . '-reading' };
    $settings->{'nodes'} = { };
    determine_work_custom_fill_colors($c, $settings, $node_counts, $node_references_counts);

    my $ref_rs = $c->model('DB::WorkReference')
        ->search(
        {
            referenced_work_id => { -in => \@work_ids },
            referencing_work_id => { -in => \@work_ids },
        }, { });

    my $output_file_name = create_graph(undef, $c, $works_rs, $ref_rs, $settings);

    return $output_file_name;
}

=head2 create_work_connected_component_graph

TODO: Describe me (similar to create_work_graph).

=cut

sub create_work_connected_component_graph {
    my ($c, $work) = @_;
    my $work_id = $work->id;
    my $works_rs;

    # If a user is logged in, replace the work with a new instance of the work
    # that also has the user's data.  This search here can be optimized by
    # only (always) having the work id passed in instead of a work.
    $work_id = $work->id;
    if ($c->user_exists) {
        $works_rs = $c->model('DB::WorkConnectedComponent')
            ->search({ },
                     {
                         bind => [ $work_id, $c->user->id ],
                     });
    }
    else {
        $works_rs = $c->model('DB::WorkConnectedComponent')
            ->search({ },
                     {
                         bind => [ $work_id, undef ],
                     });
    }

    my ($node_counts, $node_references_counts)
        = determine_node_counts_and_reference_counts($c, $works_rs);
    my @work_ids = keys %$node_counts;

    my $settings = { 'file_name' => 'work' . $work_id . '-connected-component' };
    $settings->{'nodes'} = { };
    determine_work_custom_fill_colors($c, $settings, $node_counts, $node_references_counts);

    my $ref_rs = $c->model('DB::WorkReference')
        ->search(
        {
            referenced_work_id => { -in => \@work_ids },
            referencing_work_id => { -in => \@work_ids },
        }, { });

    my $output_file_name = create_graph(undef, $c, $works_rs, $ref_rs, $settings);

    return $output_file_name;
}

sub determine_node_counts_and_reference_counts {
    my ($c, $works_rs) = @_;

    my ($node_counts, $node_references_counts) = ({ }, { });

    while (my $work = $works_rs->next) {
        $node_counts->{$work->work_id} = { } unless $node_counts->{$work->work_id};
        $node_counts->{$work->work_id}->{'num'}++;
        #$node_counts->{$work->work_id}->{'understood_rating'} = $work->understood_rating;
        $node_counts->{$work->work_id}->{'understood_rating'}
            = $work->get_column('understood_rating');

        next unless defined $work->get_column('referencing_work_id')
          && $work->get_column('referencing_work_id') >= 0;

        $node_references_counts->{$work->get_column('referencing_work_id')} = { }
            unless $node_references_counts->{$work->get_column('referencing_work_id')};
        $node_references_counts->{$work->get_column('referencing_work_id')}->{'num'}++;
        $node_references_counts->{$work->get_column('referencing_work_id')}->{'has_unrated_references'} = 1
            unless defined $work->get_column('understood_rating');

        # Set this work's minimum understanding to the current reference's value, but only
        # if the current reference has an understood rating and it is less than the work's
        # current minimum understanding.
        if (defined $work->get_column('understood_rating')
            && (!defined $node_references_counts->{$work->get_column('referencing_work_id')}->{'min_understanding'}
                || $node_references_counts->{$work->get_column('referencing_work_id')}->{'min_understanding'} > $work->get_column('understood_rating'))) {
            $node_references_counts->{$work->get_column('referencing_work_id')}->{'min_understanding'} = $work->get_column('understood_rating');
        }
    }
    $works_rs->reset;

    return ($node_counts, $node_references_counts);
}

sub determine_work_custom_fill_colors {
    my ($c, $settings, $node_counts, $node_references_counts) = @_;
    $settings = { } unless $settings;
    $settings->{'nodes'} = { } unless $settings->{'nodes'};

    foreach my $work_id (keys %$node_counts) {
        my $work = $node_counts->{$work_id};
        $settings->{'nodes'}->{$work_id} = { };

        if (defined $work->{'understood_rating'} && $work->{'understood_rating'} > 7.5) {
            # If we understand this work, color it green.
            $settings->{'nodes'}->{$work_id}->{'fill_color'} = '#66FF66';
        }
        elsif(defined $work->{'understood_rating'} && $work->{'understood_rating'} <= 7.5
              && !$node_references_counts->{$work_id}) {
            # If we do not understand this work and we do not have any of its references,
            # color it pink -- get more references!
            $settings->{'nodes'}->{$work_id}->{'fill_color'} = '#FF7EBD'; #'#FF0099';
        }
        elsif(!$node_references_counts->{$work_id}) {
            # If this work does not reference anything else, color it yellow.
            $settings->{'nodes'}->{$work_id}->{'fill_color'} = '#FFFF99'; # #FFFF66 matches the border
        }
        elsif(defined $node_references_counts->{$work_id}->{'min_understanding'}
              && $node_references_counts->{$work_id}->{'min_understanding'} <= 7.5) {
            # If we do not understand some of this work's references, color it red.
            $settings->{'nodes'}->{$work_id}->{'fill_color'} = '#FF3333';
        }
        elsif($node_references_counts->{$work_id}->{'has_unrated_references'}) {
            # If we have not read some of this work's references, color it orange.
            $settings->{'nodes'}->{$work_id}->{'fill_color'} = '#FF9966';
        }
        elsif(defined $node_references_counts->{$work_id}->{'min_understanding'}
              && $node_references_counts->{$work_id}->{'min_understanding'} > 7.5) {
            # If we understand all of this work's references, color it blue.
            $settings->{'nodes'}->{$work_id}->{'fill_color'} = '#4851FF';
        }
    }
}

=head2 create_graph

Creates a graph of work(s) and relationships and writes it to a file.

The parameters are:
  $self
  $c - The Catalyst object.
  $works_rs - The set of works to create nodes for and graph.
  $ref_rs - The set of references to graph as edges.
  $settings - Hash ref of settings.  Includes a key for the file name.

The return value is a scalar string with the name of the created file (not the
full path).

=cut

sub create_graph {
    my ($self, $c, $works_rs, $ref_rs, $settings) = @_;

    my $g = GraphViz2->new(
        global => { directed => 1, format => 'png' },
        graph => {
            start => 'random',
            #layout => 'sfdp',
            overlap => 'scalexy',
            #rankdir => 'LR',
        },
        #verbose => 1,

        #layout => 'sfdp',
        #overlap => 'scalexy', # 'false' works well but makes a big graph
        #random_start => 'true'
        );

    while (my $work = $works_rs->next) {
        #$c->log->debug($work->display_name);
        my $work_node = create_node_from_work($c, $work, $settings);

        #$c->log->debug("label: $label");
        $g->add_node(name => $work_node->{'name'}, label => $work_node->{'label'},
                     shape => $work_node->{'shape'}, style => $work_node->{'node_style'},
                     color => $work_node->{'outline_color'},
                     fillcolor => $work_node->{'fill_color'});
    }

    # Create edges for references, either by creating an  edge between two
    # existing works, or creating a node for the referenced work that does not
    # exist and creating an edge to that.
    my $work_references_counts = { };
    my $ref_work_id = -1;
    my $ref_num = 0;
    while (my $ref = $ref_rs->next) {
        # Get the id of the current referencing work.  Increment
        # its number of references and retrieve the new value.
        $ref_work_id = $ref->referencing_work_id;
        $work_references_counts->{$ref_work_id}++;
        $ref_num = $work_references_counts->{$ref_work_id};

        #$c->log->debug($ref->id . "\t" . $ref->referencing_work_id . "\t" .
        #               ($ref->referenced_work_id || "NULL") . "\t" . $ref->reference_type_id . "\t" .
        #               $ref->rank . "\t" . ($ref->chapter || "NULL") . "\t" . ($ref->reference_text || "NULL"));

        if ($ref->referenced_work_id) {
            # if the referenced work exists, simply create an edge between them
            $g->add_edge(from => $ref->referencing_work_id, to => $ref->referenced_work_id);
        }
        else {
            # if the referenced work does not exist, create a new node an an
            # edge to it
            my $node_name = $ref->referencing_work_id . "-" . $ref_num;

            # some of the reference_text values throw an error when used as the
            # node name or able, so leave that out until we can scrub the text
            # properly
            $g->add_node(name => $node_name, label => $node_name, shape => 'record', style => 'dotted'); # label => $ref->reference_text,
            $g->add_edge(from => $ref->referencing_work_id, to => $node_name);
        }
    }

    # export the graph
    my $format = "png";
    my $output_file_name = ($settings->{'file_name'} || 'works') . '.png';
    my $output_file = $c->path_to('root', 'static', 'images',
                                  $output_file_name)->stringify;
    #$c->log->debug($output_file);
    #$g->as_png($c->path_to('root', 'static', 'images', 'works.png')->stringify);
    #$g->run(format => 'svg', output_file => $output_file);
    my $gv_command = join('', @{$g->command->print}) . "}\n";

    #$c->log->debug("graphviz command: " . $gv_command);
    #$c->log->debug("diver: " . $g->global->{driver});
    #$c->log->debug("dot_output: " . $g->dot_output());

    my $fh = File::Temp->new(EXLOCK => 0);
    my $input_file = $fh->filename;

    binmode $fh;
    print $fh $gv_command;
    close $fh;

    system($g->global->{driver}, "-T$format", "-o$output_file", $input_file);

    #$c->stash(graph_file_name => $output_file_name);
    #$c->stash(template => 'works/graph.tt2');

    return $output_file_name;
}

=head2 create_node_from_work_id

TODO: Describe me

=cut

sub create_node_from_work_id {
    my ($c, $work_id) = @_;

    #my $work = $c->stash->{works_rs}->find({ work_id => $work_id },
    #                                       { key => 'primary' });
    my $work;
    if (!$c->user_exists) {
        $work = $c->model('DB::Work')
            ->find({work_id => {'=', $work_id}});
    }
    else {
        $work = $c->model('DB::Work')
            ->find(
            {
                work_id => {'=', $work_id},
                -or => [
                     'user_work_datas.user_id' => $c->user->id,
                     'user_work_datas.user_id' => undef,
                    ],
            },
            {
                join => 'user_work_datas',
                prefetch => 'user_work_datas',
                '+select' => [ 'user_work_datas.read_timestamp', 'user_work_datas.understood_rating', 'user_work_datas.approval_rating' ],
                '+as' => [ 'uwd_read_timestamp', 'uwd_understood_rating', 'uwd_approval_rating' ],
            });
    }

    return undef unless ($work);
    return create_node_from_work($c, $work);
}

=head2 create_node_from_work

TODO: Describe me

=cut
sub create_node_from_work {
    my ($c, $work, $settings) = @_;
    my $work_node = {};

    $work_node->{'name'} = $work->work_id;
    $work_node->{'shape'} = 'record';

    if (!$work->num_references) {
        $work_node->{'outline_color'} = 'red';
        $work_node->{'node_style'} = 'filled';
    }
    elsif ($work->num_references != $c->model('DB::WorkReference')->search({ referencing_work_id => $work->work_id})->count) {
        $work_node->{'outline_color'} = 'yellow';
        $work_node->{'node_style'} = 'filled';
    }
    else {
        $work_node->{'outline_color'} = 'black';
        $work_node->{'node_style'} = 'filled';
    }

    if ($settings && $settings->{'nodes'} && $settings->{'nodes'}->{$work->work_id}
        && $settings->{'nodes'}->{$work->work_id}->{'fill_color'}) {
        $work_node->{'fill_color'} = $settings->{'nodes'}->{$work->work_id}->{'fill_color'};
    }
    elsif ($c->user_exists
           && (($work->has_column_loaded('uwd_read_timestamp')
                && $work->get_column('uwd_read_timestamp'))
               || ($work->has_column_loaded('read_timestamp')
                   && $work->get_column('read_timestamp')))) {
        $work_node->{'fill_color'} = '#b3cde3';
    } else {
        $work_node->{'fill_color'} = 'gray';
    }

    if ($work->has_column_loaded('depth')) {
        $work_node->{'depth'} = $work->depth;
    }

    my $node_label;
    $node_label = $work->display_name;
    $node_label .= " (" . $work->year . ")" if $work->year;

    my $author_list = "None";
    if ($work->author_count > 0) {
        $author_list = $work->author_list;
        $author_list = substr($author_list, 0, 70) . "..." if length($author_list) > 73;
    }

    #my $tags_rs = $work->search_related_rs("source_work_tags", { },
    #                                       { join => { tag => [ 'source', 'tag_type' ] },
    #                                         '+select' => [ 'tag.name', 'source.id', 'source.name', 'tag_type.id', 'tag_type.name' ],
    #                                         '+as'     => [ 'tag_name', 'source_id', 'source_name', 'tag_type_id', 'tag_type_name' ],
    #                                         order_by  => [ 'source.name', 'tag_type.name', 'me.name' ] } );
    #my $tag_list = "";
    #while (my $tag = $tags_rs->next) {
    #    $tag_list .= ", " unless $tag_list eq "";
    #    $tag_list .= $tag->get_column('tag_name') . " (" . $tag->get_column('tag_type_name')
    #        . " | " . $tag->get_column('source_name') . ")";
    #}

    my $category_list = "None";
    my @categories;
    foreach my $category ($work->source_categories) {
        push @categories, $category->display_name;
    }
    if (scalar @categories > 0) {
        $category_list = join(', ', @categories);
        $category_list = substr($category_list, 0, 60) . "..." if length($category_list) > 63;
    }

    my $tag_list = "None";
    my @tags;
    foreach my $tag ($work->source_tags) {
        push @tags, $tag->display_name;
    }
    if (scalar @tags > 0) {
        $tag_list = join(', ', @tags);
        $tag_list = substr($tag_list, 0, 60) . "..." if length($tag_list) > 63;
    }

    my $user_info = "";
    my $read_timestamp =
        (($work->has_column_loaded('uwd_read_timestamp')
          && $work->get_column('uwd_read_timestamp'))
         || ($work->has_column_loaded('read_timestamp')
             && $work->get_column('read_timestamp'))) || "Never";
    my $understood_rating =
        (($work->has_column_loaded('uwd_understood_rating')
          && $work->get_column('uwd_understood_rating'))
         || ($work->has_column_loaded('understood_rating')
             && $work->get_column('understood_rating'))) || "N/A";
    my $approval_rating =
        (($work->has_column_loaded('uwd_approval_rating')
          && $work->get_column('uwd_approval_rating'))
         || ($work->has_column_loaded('approval_rating')
             && $work->get_column('approval_rating'))) || "N/A";
    if ($c->user_exists) {
        $user_info .= "Date Read: " . $read_timestamp . ", "
            . "Understood: " . $understood_rating . ", "
            . "Approval: " . $approval_rating;
        $user_info =
qq(  <tr>
    <td align="left">$user_info</td>
  </tr>);
    }


    $work_node->{'label'} = qq(<
<table border="0" >
  <tr>
    <td align="left">$node_label</td>
  </tr>
  <tr>
    <td align="left"><i>Authors: $author_list</i></td>
  </tr>
  <tr>
    <td align="left">Categories: $category_list</td>
  </tr>
  <tr>
    <td align="left">Tags: $tag_list</td>
  </tr>
  $user_info
</table>>);
    $work_node->{'label'} = join('', split(/\n/, $work_node->{'label'}));

    return $work_node;
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
