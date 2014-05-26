#!/usr/bin/perl -w
# This is a pseudo Perl file to test Kate's Perl syntax highlighting.
# TODO: this is incomplete, add more syntax examples!

sub prg($)
{
	my $var = shift;

	$var =~ s/bla/foo/igs;
	$var =~ s!bla!foo!igs;
	$var =~ s#bla#foo#igs;
	$var =~ tr/a-z/A-Z/;
	($match) = ($var =~ m/(.*?)/igs);

	$test = 2/453453.21;
	$test /= 2;

	print qq~d fsd fsdf sdfl sd~
	
	$" = '/';
	
	$foo = <<__EOF;
d ahfdklf klsdfl sdf sd
  SHOULD NOT MATCH: __EOF <--
fsd sdf sdfsdlkf sd
__EOF

	$x = "dasds";

	next if( $match eq "two" );
	next if( $match =~ /go/i );

	@array = (1,2,3);		# a comment
	@array = qw(apple foo bar);
	push(@array, 4);
	%hash = (red => 'rot',
		blue => 'blau');
	print keys(%hash);
}

sub blah {
}

&blah;
prg("test");

# highlighting '-f' as Operator.
$cfg = Config::IniFiles->new( -file => "/path/to/config_file.ini" );
