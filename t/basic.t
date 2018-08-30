package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'App::AckX::Preflight::Util'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight::Util', qw{
    ARRAY_REF HASH_REF SCALAR_REF
    SYNTAX_CODE SYNTAX_COMMENT SYNTAX_DATA SYNTAX_DOCUMENTATION
	SYNTAX_OTHER
    __die __err_exclusive __file_id
    __getopt __getopt_for_plugin __open_for_read __warn
    }
    or BAIL_OUT;

require_ok 'App::AckX::Preflight'
    or BAIL_OUT $@;

can_ok 'App::AckX::Preflight', qw{ new global home run }
    or BAIL_OUT;

note 'Plugins';

foreach ( qw{
	App::AckX::Preflight::Plugin
	App::AckX::Preflight::Plugin::Expand
	App::AckX::Preflight::Plugin::File
	App::AckX::Preflight::Plugin::Syntax
    } ) {

    my $class = $_;

    my $in_service = ( $class =~ s/ \A - //smx ) ? 0 : 1;

    require_ok $class
	or BAIL_OUT $@;

    can_ok $class, qw{
	IN_SERVICE
	__normalize_options
	__options
	__peek_opt
	__process
    };

    cmp_ok $class->IN_SERVICE, '==', $in_service,
	"$class is@{[ $in_service ? ' ' : ' not ' ]}in service";

}

note 'Syntax filters';

foreach ( qw{
	App::AckX::Preflight::Syntax
	App::AckX::Preflight::Syntax::_cc_like
	App::AckX::Preflight::Syntax::_nesting
	App::AckX::Preflight::Syntax::_single_line_comments
	App::AckX::Preflight::Syntax::Ada
	App::AckX::Preflight::Syntax::Asm
	App::AckX::Preflight::Syntax::Batch
	App::AckX::Preflight::Syntax::Cc
	App::AckX::Preflight::Syntax::Cpp
	App::AckX::Preflight::Syntax::Csharp
	App::AckX::Preflight::Syntax::Data
	App::AckX::Preflight::Syntax::Fortran
	App::AckX::Preflight::Syntax::Haskell
	App::AckX::Preflight::Syntax::Java
	App::AckX::Preflight::Syntax::Lisp
	App::AckX::Preflight::Syntax::Lua
	App::AckX::Preflight::Syntax::Make
	App::AckX::Preflight::Syntax::Ocaml
	App::AckX::Preflight::Syntax::Pascal
	App::AckX::Preflight::Syntax::Perl
	App::AckX::Preflight::Syntax::SQL
	App::AckX::Preflight::Syntax::Shell
	App::AckX::Preflight::Syntax::Swift
	App::AckX::Preflight::Syntax::Vim
	App::AckX::Preflight::Syntax::YAML
    } ) {

    my $class = $_;

    my $in_service = ( $class =~ s/ \A - //smx ) ? 0 : 1;

    require_ok $class
	or BAIL_OUT $@;

    can_ok $class, qw{
	IN_SERVICE
	IS_EXHAUSTIVE
	__get_syntax_opt
	__handles_syntax
	__handles_type
	import
	__normalize_options
	__plugins
	__want_everything
	__want_syntax
    }
	or BAIL_OUT;

    cmp_ok $class->IN_SERVICE, '==', $in_service,
	"$class is@{[ $in_service ? ' ' : ' not ' ]}in service";

}

done_testing;

1;

# ex: set textwidth=72 :
