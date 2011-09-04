use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'PAPS' }
BEGIN { use_ok 'PAPS::Controller::SourceCategoryTypes' }

ok( request('/sourcecategorytypes')->is_success, 'Request should succeed' );
done_testing();
