package main;

use 5.008008;

use strict;
use warnings;

use App::AckX::Preflight;
use App::AckX::Preflight::Util qw{ __interpret_plugins };
use Test2::V0;

use lib qw{ inc };
use My::Module::Preflight;

use constant PACKAGE	=> 'My::Module::Preflight';


is [ sort My::Module::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::Expand
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Perldoc
	App::AckX::Preflight::Plugin::Syntax
	} ],
    'Plugins';

{
    # DANGER WILL ROBINSON! ENCAPSULATION VIOLATION!
    my $aapx = bless {
	disable	=> {
	    'App::AckX::Preflight::Plugin::File'	=> 1,
	},
    }, PACKAGE;
    is [ sort $aapx->__plugins() ],
	[ qw{
	    App::AckX::Preflight::Plugin::Expand
	    App::AckX::Preflight::Plugin::Perldoc
	    App::AckX::Preflight::Plugin::Syntax
	    } ],
	'Plugins with File disabled';
}

is marshal( qw{ A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Expand
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Perldoc
	App::AckX::Preflight::Plugin::Syntax
	} ],
    'Default order';

=begin comment

is marshal( qw{ --manifest A B C } ),		# FilesFrom
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
	} ],
    '--manifest ignored';

is marshal( qw{ --nomanifest A B C } ),		# FilesFrom
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
	} ],
    '--nomanifest ignored';

is marshal( qw{ --no-manifest A B C } ),		# FilesFrom
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
	} ],
    '--no-manifest ignored';

is marshal( qw{ --manifest --file x A B C } ),	# FilesFrom
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
	} ],
    '--manifest --file x ignored';

=end comment

=cut

is marshal( qw{ --file x --manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Expand
	App::AckX::Preflight::Plugin::Perldoc
	App::AckX::Preflight::Plugin::Syntax
	} ],
    '--file x --manifest uses that order';

is marshal( qw{ --manifest --file x --no-manifest A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Expand
	App::AckX::Preflight::Plugin::Perldoc
	App::AckX::Preflight::Plugin::Syntax
	} ],
    '--manifest --file x --no-manifest pulls File to front';

is marshal( qw{ --syntax=code A B C } ),
    [ qw{
	App::AckX::Preflight::Plugin::Syntax
	App::AckX::Preflight::Plugin::Expand
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Perldoc
	} ],
    '--syntax=code pulls Syntax to front';

done_testing;

1;

sub marshal {
    local @ARGV = @_;
    my $invocant = ref @ARGV ? shift @ARGV : PACKAGE;
    return [
	map { $_->{class} } __interpret_plugins( $invocant->__plugins() )
    ];
};

# ex: set textwidth=72 :
