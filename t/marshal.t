package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Test qw{ -search-test };

use constant PACKAGE	=> 'App::AckX::Preflight';


is_deeply [ sort App::AckX::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Reverse
	} ],
    'Plugins'
	or diag explain [ App::AckX::Preflight->__plugins() ];

is_deeply marshal( qw{ A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Reverse
	} ],
    'Default order';

is_deeply marshal( qw{ --reverse A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Reverse
	App::AckX::Preflight::Plugin::File
	} ],
    '--reverse pulls Reverse to front';

is_deeply marshal( qw{ --noreverse A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Reverse
	App::AckX::Preflight::Plugin::File
	} ],
    '--noreverse pulls Reverse to front';

is_deeply marshal( qw{ --no-reverse A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Reverse
	App::AckX::Preflight::Plugin::File
	} ],
    '--no-reverse pulls Reverse to front';

is_deeply marshal( qw{ --reverse --file x A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Reverse
	App::AckX::Preflight::Plugin::File
	} ],
    '--reverse --file x pulls Reverse to front';

is_deeply marshal( qw{ --file x --reverse A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Reverse
	} ],
    '--file x --reverse uses that order';

done_testing;

1;

sub marshal {
    local @ARGV = @_;
    return [
	map { $_->{package} } PACKAGE->__marshal_plugins(),
    ];
};

# ex: set textwidth=72 :
