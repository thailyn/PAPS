package PAPS::Schema::Result::WorkTypes;

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

PAPS::Schema::Result::WorkTypes

=cut

__PACKAGE__->table("work_types");

=head1 ACCESSORS

=head2 work_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'work_types_work_type_id_seq'

=head2 work_type

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "work_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "work_types_work_type_id_seq",
  },
  "work_type",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("work_type_id");

=head1 RELATIONS

=head2 works

Type: has_many

Related object: L<PAPS::Schema::Result::Works>

=cut

__PACKAGE__->has_many(
  "works",
  "PAPS::Schema::Result::Works",
  { "foreign.work_type_id" => "self.work_type_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-01-29 22:32:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5H/03fRq2AmsErLWm0v6fQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
