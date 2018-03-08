package main;

use 5.008008;

use strict;
use warnings;

use Module::Pluggable::Object;

BEGIN {

    # This horrible hack is because Module::Pluggable::Object insists on
    # grooming @INC if it detects that it is running a distribution
    # test. And I want that, because I do not want to pull in rogue
    # plugins once they exist. But I also do not want to distribute any
    # plugins with this distribution. So the testing plugins have to
    # live somewhere else, and that somewhere needs to be injected back
    # into the search list AFTER it is groomed. And without changing any
    # source code. So my solution (as taught in the Conan the Barbarian
    # school of programming) is to modify
    # Module::Pluggable::Object::new().
    #
    # This MUST be done in a BEGIN block BEFORE App::AckX::Preflight is
    # loaded, because the Module::Pluggable::Object object is
    # instantiated when App::AckX::Preflight is loaded.

    my $old_new = \&Module::Pluggable::Object::new;

    no warnings qw{ redefine };

    *Module::Pluggable::Object::new = sub {
	my ( $class, %opt ) = @_;
	push @{ $opt{search_dirs} ||= [] }, 't/lib';
	return $old_new->( $class, %opt );
    };
}

use App::AckX::Preflight;

BEGIN {

    # Hot-plug the __execute() method to simply return its arguments,
    # since what they are constitutes the basis of this test.

    no warnings qw{ redefine };

    *App::AckX::Preflight::__execute = sub {
	my ( undef, @arg ) = @_;
	return @arg;
    };
}

use Test::More 0.88;	# Because of done_testing();


is_deeply [ sort App::AckX::Preflight->__plugins() ],
    [ qw{
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Reverse
	} ],
    'Plugins';

is_deeply xqt( qw{ A B C } ),
    [ qw{ ack A B C } ],
    'No reversal by default';

is_deeply xqt( qw{ --noreverse A B C } ),
    [ qw{ ack A B C } ],
    '--noreverse';

is_deeply xqt( qw{ --reverse A B C } ),
    [ qw{ ack C B A } ],
    '--reverse';

is_deeply xqt( qw{ --file t/data/foo } ),
    [ qw{ ack --match (?i:\bfoo\b) } ],
    '--file t/data/foo';

SKIP: {

    '5.010' le $]
	or skip( "Perl 5.10 required; this is $]", 1 );

    is_deeply xqt( qw{ --file t/data/fubar } ),
	[ qw{ ack --match (?|(?i:\bfu\b)|(?i:\bbar\b)) } ],
	'--file t/data/fubar';
}

# Test combining non-transitive plug-ins.

is_deeply xqt( qw{ --reverse t/data/foo --file t/data/fubar } ),
    [ qw{ ack --match (?i:\bfoo\b) t/data/fubar } ],
    '--reverse --file';

is_deeply xqt( qw{ --file t/data/foo --reverse fubar } ),
    [ qw{ ack fubar (?i:\bfoo\b) --match } ],	# This won't execute
    '--file --reverse';

done_testing;

sub xqt {
    local @ARGV = @_;

    return [ App::AckX::Preflight->run() ];

}

1;

# ex: set textwidth=72 :
