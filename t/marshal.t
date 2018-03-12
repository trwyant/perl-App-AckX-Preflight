package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Preflight;

use constant PACKAGE	=> 'My::Module::Preflight';


is_deeply [ sort My::Module::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Manifest
	} ],
    'Plugins'
	or diag explain [ App::AckX::Preflight->__plugins() ];

is_deeply marshal( qw{ A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Manifest
	} ],
    'Default order';

is_deeply marshal( qw{ --manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Manifest
	App::AckX::Preflight::Plugin::File
	} ],
    '--manifest pulls Manifest to front';

is_deeply marshal( qw{ --nomanifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Manifest
	App::AckX::Preflight::Plugin::File
	} ],
    '--nomanifest pulls Manifest to front';

is_deeply marshal( qw{ --no-manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Manifest
	App::AckX::Preflight::Plugin::File
	} ],
    '--no-manifest pulls Manifest to front';

is_deeply marshal( qw{ --manifest --file x A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Manifest
	App::AckX::Preflight::Plugin::File
	} ],
    '--manifest --file x pulls Manifest to front';

is_deeply marshal( qw{ --file x --manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Manifest
	} ],
    '--file x --manifest uses that order';

is_deeply marshal( qw{ --manifest --file x --no-manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Manifest
	} ],
    '--reverse --file x --no-reverse pulls File to front';

done_testing;

1;

sub marshal {
    local @ARGV = @_;
    return [
	map { $_->{package} } PACKAGE->__marshal_plugins(),
    ];
};

# ex: set textwidth=72 :
