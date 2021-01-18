package main;

use 5.010;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

BEGIN {
    eval {
	require Test::Prereq::Meta;
	1;
    } or plan skip_all => 'Test::Prereq::Meta not available';
}

Test::Prereq::Meta->new(
    accept	=> [ qw{
	App::AckX::Preflight::Syntax::_cc_like
	App::AckX::Preflight::Syntax::_nesting
	App::AckX::Preflight::Syntax::_single_line_comments
	My::Module::Preflight
	My::Module::TestPlugin
	My::Module::TestSyntax
	Win32
	} ],
)->all_prereq_ok();

done_testing;

1;

# ex: set textwidth=72 :
