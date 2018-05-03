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
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    'Plugins'
	or diag explain [ App::AckX::Preflight->__plugins() ];

{
    # DANGER WILL ROBINSON! ENCAPSULATION VIOLATION!
    my $aapx = bless {
	disable	=> {
	    'App::AckX::Preflight::Plugin::File'	=> 1,
	},
    }, PACKAGE;
    is_deeply [ sort $aapx->__plugins() ],
	[ qw{
	    App::AckX::Preflight::Plugin::FilesFrom
	    App::AckX::Preflight::Plugin::PerlFile
	    } ],
	'Plugins with File disabled'
	    or diag explain [ App::AckX::Preflight->__plugins() ];
}

is_deeply marshal( qw{ A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    'Default order';

is_deeply marshal( qw{ --manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    '--manifest pulls FilesFrom to front';

is_deeply marshal( qw{ --nomanifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    '--nomanifest pulls FilesFrom to front';

is_deeply marshal( qw{ --no-manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    '--no-manifest pulls FilesFrom to front';

is_deeply marshal( qw{ --manifest --file x A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    '--manifest --file x pulls FilesFrom to front';

is_deeply marshal( qw{ --file x --manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    '--file x --manifest uses that order';

is_deeply marshal( qw{ --manifest --file x --no-manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::FilesFrom
	App::AckX::Preflight::Plugin::PerlFile
	} ],
    '--manifest --file x --no-manifest pulls File to front';

is_deeply marshal( qw{ --perl-code A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::PerlFile
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::FilesFrom
	} ],
    '--perl-code pulls PerlFile to front';

done_testing;

1;

sub marshal {
    local @ARGV = @_;
    my $invocant = ref @ARGV ? shift @ARGV : PACKAGE;
    return [
	map { $_->{package} } $invocant->__marshal_plugins(),
    ];
};

# ex: set textwidth=72 :
