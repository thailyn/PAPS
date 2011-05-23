package PAPS::Schema::Result::Metaworks;

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

PAPS::Schema::Result::Metaworks

=cut

__PACKAGE__->table("metaworks");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'metaworks_id_seq'

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "metaworks_id_seq",
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 works

Type: has_many

Related object: L<PAPS::Schema::Result::Works>

=cut

__PACKAGE__->has_many(
  "works",
  "PAPS::Schema::Result::Works",
  { "foreign.meta_work_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-05-22 23:16:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cZHiEcogy/SpBKwq4SZd6Q


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
