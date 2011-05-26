package PAPS::Schema::Result::ReferenceTypes;

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

PAPS::Schema::Result::ReferenceTypes

=cut

__PACKAGE__->table("reference_types");

=head1 ACCESSORS

=head2 id

  data_type: 'smallint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'reference_types_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "smallint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "reference_types_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("reference_types_name_key", ["name"]);

=head1 RELATIONS

=head2 work_references

Type: has_many

Related object: L<PAPS::Schema::Result::WorkReferences>

=cut

__PACKAGE__->has_many(
  "work_references",
  "PAPS::Schema::Result::WorkReferences",
  { "foreign.reference_type_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-05-25 23:06:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3a4tb1rkdAIZ5MMAZB0y8Q


# You can replace this text with custom content, and it will be preserved on regeneration

# Helper methods

=head2 display_name

Returns a string suitable to represent the essence of this object.

=cut

sub display_name {
    my ($self) = @_;

    my $name = $self->name;
    return $name;
}

__PACKAGE__->meta->make_immutable;
1;
