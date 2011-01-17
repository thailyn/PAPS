package paps::Schema::Result::People;

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

paps::Schema::Result::People

=cut

__PACKAGE__->table("people");

=head1 ACCESSORS

=head2 person_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'people_person_id_seq'

=head2 first_name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 middle_name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 last_name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 date_of_birth

  data_type: 'date'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "person_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "people_person_id_seq",
  },
  "first_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "middle_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "last_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "date_of_birth",
  { data_type => "date", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("person_id");

=head1 RELATIONS

=head2 work_authors

Type: has_many

Related object: L<paps::Schema::Result::WorkAuthors>

=cut

__PACKAGE__->has_many(
  "work_authors",
  "paps::Schema::Result::WorkAuthors",
  { "foreign.person_id" => "self.person_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-01-17 14:13:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/1Y7/8+OUkhk2leIlPTNjw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
