use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'PAPS' }
BEGIN { use_ok 'PAPS::Controller::SourceTags' }

ok( request('/sourcetags')->is_success, 'Request should succeed' );
done_testing();
