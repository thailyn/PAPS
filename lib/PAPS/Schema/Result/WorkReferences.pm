package PAPS::Schema::Result::WorkReferences;

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

PAPS::Schema::Result::WorkReferences

=cut

__PACKAGE__->table("work_references");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'work_references_id_seq'

=head2 referencing_work_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 referenced_work_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reference_type_id

  data_type: 'smallint'
  is_foreign_key: 1
  is_nullable: 0

=head2 rank

  data_type: 'smallint'
  is_nullable: 0

=head2 chapter

  data_type: 'smallint'
  is_nullable: 1

=head2 reference_text

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "work_references_id_seq",
  },
  "referencing_work_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "referenced_work_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reference_type_id",
  { data_type => "smallint", is_foreign_key => 1, is_nullable => 0 },
  "rank",
  { data_type => "smallint", is_nullable => 0 },
  "chapter",
  { data_type => "smallint", is_nullable => 1 },
  "reference_text",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 referenced_work_id

Type: belongs_to

Related object: L<PAPS::Schema::Result::Works>

=cut

__PACKAGE__->belongs_to(
  "referenced_work_id",
  "PAPS::Schema::Result::Works",
  { work_id => "referenced_work_id" },
);

=head2 referencing_work_id

Type: belongs_to

Related object: L<PAPS::Schema::Result::Works>

=cut

__PACKAGE__->belongs_to(
  "referencing_work_id",
  "PAPS::Schema::Result::Works",
  { work_id => "referencing_work_id" },
);

=head2 reference_type_id

Type: belongs_to

Related object: L<PAPS::Schema::Result::ReferenceTypes>

=cut

__PACKAGE__->belongs_to(
  "reference_type_id",
  "PAPS::Schema::Result::ReferenceTypes",
  { id => "reference_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-05-25 23:06:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IFXEX9XBjWGILSmcGA4RlA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
