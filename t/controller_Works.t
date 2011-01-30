use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'PAPS' }
BEGIN { use_ok 'PAPS::Controller::Works' }

ok( request('/works')->is_success, 'Request should succeed' );
done_testing();
