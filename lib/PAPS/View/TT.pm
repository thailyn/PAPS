package PAPS::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt2',
    INCLUDE_PATH => [
        PAPS->path_to( 'root', 'src' ),
    ],
    WRAPPER => 'wrapper.tt2',
    render_die => 1,
);

=head1 NAME

PAPS::View::TT - TT View for PAPS

=head1 DESCRIPTION

TT View for PAPS.

=head1 SEE ALSO

L<PAPS>

=head1 AUTHOR

Charles Macanka,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
