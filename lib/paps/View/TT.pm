package paps::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt2',
    INCLUDE_PATH => [
        paps->path_to( 'root', 'src' ),
    ],
    render_die => 1,
);

=head1 NAME

paps::View::TT - TT View for paps

=head1 DESCRIPTION

TT View for paps.

=head1 SEE ALSO

L<paps>

=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
