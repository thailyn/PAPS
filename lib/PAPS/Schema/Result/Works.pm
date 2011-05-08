package PAPS::Schema::Result::Works;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

PAPS::Schema::Result::Works

=cut

__PACKAGE__->table("works");

=head1 ACCESSORS

=head2 work_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'works_work_id_seq'

=head2 work_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 subtitle

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 edition

  data_type: 'smallint'
  is_nullable: 1

=head2 num_references

  data_type: 'smallint'
  is_nullable: 1

=head2 doi

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "work_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "works_work_id_seq",
  },
  "work_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "subtitle",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "edition",
  { data_type => "smallint", is_nullable => 1 },
  "num_references",
  { data_type => "smallint", is_nullable => 1 },
  "doi",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("work_id");

=head1 RELATIONS

=head2 work_authors

Type: has_many

Related object: L<PAPS::Schema::Result::WorkAuthors>

=cut

__PACKAGE__->has_many(
  "work_authors",
  "PAPS::Schema::Result::WorkAuthors",
  { "foreign.work_id" => "self.work_id" },
  {},
);

=head2 work_type_id

Type: belongs_to

Related object: L<PAPS::Schema::Result::WorkTypes>

=cut

__PACKAGE__->belongs_to(
  "work_type_id",
  "PAPS::Schema::Result::WorkTypes",
  { work_type_id => "work_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-01-29 23:53:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cm4WszX8TDtz4TvhAB8Cyw


# You can replace this text with custom content, and it will be preserved on regeneration

# many_to_many():
#   args:
#     1) Name of relationship, DBIC will create accessor with this name
#     2) Name of has_many() relationship this many_to_many() is shortcut for
#     3) Name of belongs_to() relationship in model class of has_many() above
#   You must already have the has_many() defined to use a many_to_many().
__PACKAGE__->many_to_many(authors => 'work_authors', 'person_id',
                          {
                              '+select' => 'me.author_position',
                              '+as' => 'author_position',
                          });


# Helper methods

=head2 display_name

Returns a formatted version of the title and subtitle suitable for display.

=cut

sub display_name {
    my ($self) = @_;

    my $name = $self->title;
    $name .= ': ' . $self->subtitle if defined $self->subtitle;
    return $name;
}

=head2 doi_url

Returns a complete URL based off of the doi value.

=cut

sub doi_url {
    my ($self) = @_;

    my $url;
    $url = 'http://doi.acm.org/' . $self->doi;
    return $url;
}

=head2 author_count

Return the number of authors for the current work.

=cut

sub author_count {
    my ($self) = @_;

    # This uses the many-to-many relationship to get all of the authors for the current
    # work, and uses the 'count' method in DBIx::Class::ResultSet to get an SQL COUNT.
    return $self->authors->count;
}


=head2 author_list

Return a comma-separated list of authors for the current book

=cut

sub author_list {
    my ($self) = @_;

    # Loop through all authors for the current work, calling the 'full_name' method
    # on each to get the name to use.
    my @names;
    foreach my $author ($self->authors) {
        push(@names, $author->full_name);
    }

    return join(', ', @names);
}

__PACKAGE__->meta->make_immutable;
1;
