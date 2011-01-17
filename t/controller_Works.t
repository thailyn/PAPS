use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'paps' }
BEGIN { use_ok 'paps::Controller::Works' }

ok( request('/works')->is_success, 'Request should succeed' );
done_testing();
