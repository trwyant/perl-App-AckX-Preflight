package main;

use 5.008008;

use strict;
use warnings;

use App::Ack::Filter::Extension;
use App::Ack::Resource;
use App::AckX::Preflight::Resource;
use App::AckX::Preflight::via::PerlFile;
use Scalar::Util qw{ blessed openhandle };
use Test::More 0.88;	# Because of done_testing();

use constant PERL_FILE	=> 't/data/perl_file.PL';

use constant PERL_CODE	=> <<'EOD';
   1: #!/usr/bin/env perl
   2:
   3: use strict;
   4: use warnings;
   5:
EOD

use constant PERL_DATA	=> <<'EOD';
   6: __END__
   7:
   8: This is data, kinda sorta.
   9:
EOD

use constant PERL_POD	=> <<'EOD';
  10: =head1 TEST
  11:
  12: This is a test. It is only a test.
  13:
  14: =cut
EOD

use constant PERL_CODE_POD => PERL_CODE . PERL_POD;

use constant TEXT_FILE	=> 't/data/perl_file.txt';

use constant TEXT_CONTENT	=> <<'EOD';
   1: There was a young lady named Bright,
   2: Who could travel much faster than light.
   3:     She set out one day
   4:     In a relative way
   5: And returned the previous night.
EOD

$App::Ack::mappings{perl} = [
    App::Ack::Filter::Extension->new( qw{ PL } ),
];

my $perl_resource = App::Ack::Resource->new( PERL_FILE );

my $text_resource = App::Ack::Resource->new( TEXT_FILE );

App::AckX::Preflight::via::PerlFile->import( 'code' );

is slurp( PERL_FILE ), PERL_CODE, 'Only code, reading directly';

is slurp( $perl_resource ), PERL_CODE, 'Only code, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only code, text resource';

App::AckX::Preflight::via::PerlFile->import( 'data' );

is slurp( PERL_FILE ), PERL_DATA, 'Only data, reading directly';

is slurp( $perl_resource ), PERL_DATA, 'Only data, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only data, text resource';

App::AckX::Preflight::via::PerlFile->import( 'pod' );

is slurp( PERL_FILE ), PERL_POD, 'Only POD, reading directly';

is slurp( $perl_resource ), PERL_POD, 'Only POD, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Only POD, text resource';

App::AckX::Preflight::via::PerlFile->import( 'code', 'pod' );

is slurp( PERL_FILE ), PERL_CODE_POD, 'Code and POD, reading directly';

is slurp( $perl_resource ), PERL_CODE_POD, 'Code and POD, reading resource';

is slurp( $text_resource ), TEXT_CONTENT, 'Code and POD, text resource';

done_testing;

sub slurp {
    my ( $file ) = @_;
    my $fh;
    if ( blessed( $file ) ) {
	$fh = $file->open()
	    or die "@{[ ref $file ]}->open() failed: $!\n";
    } elsif ( openhandle( $file ) ) {
	$fh = $file;
    } else {
	open $fh, '<:via(App::AckX::Preflight::via::PerlFile)', $file
	    or die "Failed to open $file: $!\n";
    }
    my $rslt;
    while ( <$fh> ) {
	s/ \s+ \z //smx;
	if ( '' eq $_ ) {
	    $rslt .= sprintf "%4d:\n", $.;
	} else {
	    $rslt .= sprintf "%4d: %s\n", $., $_;
	}
    }
    if ( blessed( $file ) ) {
	$file->close();
    } else {
	close $fh;
    }
    return $rslt;
}

1;

# ex: set textwidth=72 :
