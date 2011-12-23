use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'PAPS' }
BEGIN { use_ok 'PAPS::Controller::SourceCategories' }

ok( request('/sourcecategories')->is_success, 'Request should succeed' );
done_testing();
