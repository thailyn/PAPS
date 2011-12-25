use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'PAPS' }
BEGIN { use_ok 'PAPS::Controller::SourceTagTypes' }

ok( request('/sourcetagtypes')->is_success, 'Request should succeed' );
done_testing();
