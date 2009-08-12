#!/usr/bin/perl
#
#	author: Patrick Stein aka Jolly (original script from ortwin)
#	usage:	insert into crontab will download missing files to current working dir or the given dir ( arg ).	



use itunescredentials;

$login 		= itunescredentials::login;
$password 	= itunescredentials::password;


my $destinationdirectory = pop @ARGV;

if( -d $destinationdirectory )
{
	chdir($destinationdirectory);
}

$curlcmd='curl';

$itmsserver	= 'https://itts.apple.com';
$htmloutput = `$curlcmd "$itmsserver/cgi-bin/WebObjects/Piano.woa"`;

if( $htmloutput =~ m/form\s+method="post"\s+action="([^"]+)">/io )
{
	$action = $1;
	print "action url: $action\n";
	if( $htmloutput =~ /<input\s+type="hidden"\s+name="wosid" value="([^"]+)"\s+>/io )
	{
		$wosid=$1;
	}
}
else
{
	print STDERR __LINE__."could not find login action:\n$htmloutput\n";
	exit 1;
}

$htmloutput = `$curlcmd -d "theAccountName=$login" -d "theAccountPW=$password" -d "theAuxValue=" -d "1.Continue.x=0" -d "1.Continue.y=0" -d "wosid=wosid" "$itmsserver$action"`;

if( $htmloutput =~ m/form\s+method="post"\s+name="frmVendorPage"\s+action="([^"]+)">/io )
{
	$action = $1;
	print "action url: $action\n";
}
else
{
	print STDERR __LINE__."could not find frmVendorPage action:\n$htmloutput\n";
	exit 1;
}

$action = $1;
print "action url: $action\n";

foreach my $datetype ('Weekly','Daily')
{
	my $htmloutput = `$curlcmd -d "11.7=Summary" -d "11.9=$datetype" -d "hiddenDayOrWeekSelection=$datetype" -d "hiddenSubmitTypeName=ShowDropDown" -d "wosid=wosid" "$itmsserver$action" ` ;


	if( $htmloutput =~ m/form\s+method="post"\s+name="frmVendorPage"\s+action="([^"]+)">/io )
	{
		$subaction = $1;
		print "subaction url: $subaction\n";
	}
	else
	{
		print STDERR __LINE__."could not find frmVendorPage action:\n$htmloutput\n";
		exit 1;
	}
	if( $htmloutput =~ m/<select\s+Id="dayorweekdropdown"\s+onChange="jsClearErrorMsg\(\)\;"\s+name="([^"]+)">/io )
	{
		$datetypeaction = $1;
		print "datetypeaction url: $subaction\n";
	}
	else
	{
		print STDERR __LINE__."could not find frmVendorPage action:\n$htmloutput\n";
		exit 1;
	}

	my %missingdates;
	
	while( $htmloutput =~ m#<option\s*value="((\d\d)\/(\d\d)\/(20\d\d))">\d\d\/\d\d\/20\d\d(\s*To\s*\d\d\/\d\d\/20\d\d)?<\/option>#g )
	{
		my($option,$month,$day,$year) = ($1,$2,$3,$4);
	
		my $filename = $datetype.'.'.$year.'.'.$month.'.'.$day.'.txt.gz';
		
		if( ! -e $filename )
		{
			print "Missing dates: $1 $filename\n";
			$missingdates{$option}=$filename;
		}
	}
	
	
	while( my($option,$filename) = each(%missingdates) )
	{
		print "downloading file: $filename\n";
		`$curlcmd  -d "11.7=Summary" -d "11.9=$datetype" -d "$datetypeaction=$option" -d "hiddenDayOrWeekSelection=$datetype" -d "hiddenSubmitTypeName=Download" -d "wosid=wosid" "$itmsserver$subaction" -o $filename`;
	}
}


exit 0;

