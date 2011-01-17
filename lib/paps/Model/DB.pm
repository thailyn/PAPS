package paps::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'paps::Schema',
    
    connect_info => {
        dsn => 'dbi:Pg:dbname=papsdb',
        user => 'papsuser',
        password => '',
        AutoCommit => q{1},
    }
);

=head1 NAME

paps::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<paps>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<paps::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.48

=head1 AUTHOR

Charles Macanka

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;