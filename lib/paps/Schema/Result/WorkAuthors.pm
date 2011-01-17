package paps::Schema::Result::WorkAuthors;

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

paps::Schema::Result::WorkAuthors

=cut

__PACKAGE__->table("work_authors");

=head1 ACCESSORS

=head2 works_author_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'work_authors_works_author_id_seq'

=head2 work_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 author_position

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "works_author_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "work_authors_works_author_id_seq",
  },
  "work_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "author_position",
  { data_type => "smallint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("works_author_id");

=head1 RELATIONS

=head2 work_id

Type: belongs_to

Related object: L<paps::Schema::Result::Works>

=cut

__PACKAGE__->belongs_to(
  "work_id",
  "paps::Schema::Result::Works",
  { work_id => "work_id" },
);

=head2 person_id

Type: belongs_to

Related object: L<paps::Schema::Result::People>

=cut

__PACKAGE__->belongs_to(
  "person_id",
  "paps::Schema::Result::People",
  { person_id => "person_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-01-17 14:13:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g7F6sXitM3PldKed3PhwRQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
