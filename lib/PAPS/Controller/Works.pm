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
}

=head2 details

Show the details for a specific work.

=cut

sub details :Chained('work') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $work_id = $c->stash->{work_id};

    my $matching_work = $c->model('DB::Work')
        ->find({work_id => {'=', $work_id}});

    #$c->stash(work_id => $requested_work);
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

    # This does not work, as source_category_id is part of the primary key, and,
    # apparently, DBIx does not want to update those values.
    if (lc $params->{submit} eq 'save') {
        $work_source_category->update({
            category_id => $params->{source_category_id} || undef,
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
        my ($outline_color, $fill_color, $node_style);
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
        $g->add_node($work->work_id, label => $work->display_name,
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
    $g->as_png($c->path_to('root', 'static', 'images', 'works.png')->stringify);

    $c->stash(template => 'works/graph.tt2');
}


=head2 graph2

TODO: Describe me

=cut

sub graph2 :Chained('base') :PathPart('graph2') :Args(0) {
    my ($self, $c) = @_;

    my $g = GraphViz2->new(
        global => { directed => 1, format => 'png' },
        graph => {
            start => 'random',
            layout => 'sfdp',
            overlap => 'scalexy',
        },
        #verbose => 1,

        #layout => 'sfdp',
        #overlap => 'scalexy', # 'false' works well but makes a big graph
        #random_start => 'true'
        );
    my $works_rs = $c->stash->{works_rs};

    while (my $work = $works_rs->next) {
        #$c->log->debug($work->display_name);
        my ($outline_color, $fill_color, $node_style);
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


        my $label = qq(<
<table border="0" >
  <tr>
    <td align="left">) . $work->display_name . qq(</td>
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
</table>>);
        $label = join('', split(/\n/, $label));
        #$c->log->debug("label: $label");
        $g->add_node(name => $work->work_id, label => $label,
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
        $ref_num++;
    }

    #$c->log->debug("*** DEBUG *** Home path: " . $c->config->{home});
    #$c->log->debug("*** DEBUG *** Sample path: " . $c->path_to('root', 'static', 'images', 'works.png'));

    # export the graph
    my $format = "png";
    my $output_file = $c->path_to('root', 'static', 'images', 'works.png')->stringify;
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

    $c->stash(template => 'works/graph.tt2');
}


=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
