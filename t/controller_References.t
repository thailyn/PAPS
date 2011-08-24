use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'PAPS' }
BEGIN { use_ok 'PAPS::Controller::References' }

ok( request('/references')->is_success, 'Request should succeed' );
done_testing();
