<?Lassoscript
// Last modified 3/13/10 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			it_easythumb }
	{Description=		Creates thumbnails of entire pages using the EasyThumb service }
	{Author=			Dominique Guardiola}
	{AuthorEmail=		dguardiola@quinode.fr }
	{ModifiedBy=		Eric Landmann}
	{ModifiedByEmail=	support@iterate.ws}
	{Date=				3/13/10 }
	{Usage=				it_easythumb( -url=$ConvertThisURL, -userid=$svEasyThumbUserID, -apikey=$svEasyThumbAPIKey, -file=$PreviewFileName, -size='medium2', -debug=$EasyThumbDebug) }
	{ExpectedResults=	A thumbnail created on the EasyThumb service }
	{Dependencies=		$svEasyThumbUserID and $svEasyThumbAPIKey must be set in the siteconfig using values from bluga.net after signup }
	{DevelNotes=		See source code for this CT }
	{ChangeNotes=		3/13/10
						First implementation. Renamed the CT from cms_easythumb to it_easythumb. }
/Tagdocs;
*/
/*
Wrapper for Webthumb website snapshot REST API
Reference: http://webthumb.bluga.net

Author: Dominique Guardiola
Last Modified: Oct. 17, 2009
License: Public Domain

Description:
WebThumb snapshot Service to create a JPEG snapshot of a given URL. It requires you sign up for the service. 

Returns an HTML tag containing the URL to the JPEG thumbnail. This simple GET method permits 3 differents type of snapshots  small = 80 x 60 pixels medium = 160 x 120 pixels medium2 = 320 x 240 pixels.


Sample Usage:
it_easythumb(
	-url='http://www.example.com',
	-userid='xxxx',
	-apikey='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

To display the <img> with custom CSS class an ID, and download the thumbnail in a given path.

it_easythumb(
	-url='http://www.example.com',
	-file='/my/absolute/file/path/myfilename.jpg',
	-size='medium2',
	-userid='xxxx',
	-apikey='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

If you use the -file option, a file will be created or overwritten and the tag will return the filepath.

small = 80 x 60
medium = 160 x 120
medium2 = 320 x 240
larger = ?

#result IS NOT ACTUALLY VIEWED, for debbugging purposes only.

Downloaded from tagSwap.net on Mar. 08, 2010.
Latest version available from <http://tagSwap.net/cms_easythumb>.

----------------------------------------------------------------------------*/

define_tag: 'easythumb',
	-namespace='it_',
	-priority='replace',	
	-required='url',
	-required='apikey',
	-required='userid',
	-optional='file',
	-optional='size',
	-optional='cache',
	-optional='content_keyvalue',
	-optional='id',
	-optional='class',
	-optional='debug',
	-encodenone;
	
	Lasso_ExecutionTimeLimit: 60;

	// Used to look for valid output from EasyThumbs
	Var('CheckValid' = string);

	// Initial error vars
	Var('vError' = null);
	Var('vOption' = null);

	local('result' = string);	
	local('service_url') = 'http://webthumb.bluga.net/easythumb.php'; //can change some day
	!local_defined('size')? local('size') = 'small';  //  {small | medium | medium2}		
	!local_defined('cache')? local('cache') = '0';
	local('datestamp') = date_format((Date_LocalToGMT:date),-Format='%Y%m%d');

	local('string_url') = string(#service_url + '?user=' + #userid + '&url=' + encode_url(#url) + '&size=' + #size + '&cache=' + #cache + '&hash=' + encrypt_MD5(#datestamp + #url + #apikey));

	// UNCOMMENT to log the conversion
	Log_Critical('it_easythumb -- Converting "'(#string_url)'"');

	// Protect this block and handle errors
	Protect;

		// Go get the thumbnail from EasyCMS
		local('response') = include_url(#string_url, -timeout=0);
	
		// Copy the first 400 characters, use to check for errors
		Var('CheckValid' = (String_Extract: -startposition=1, -endposition=400, (#response)));
		
		#result += ('<b>$CheckValid = </b> '+($CheckValid)+'<br/>\n');
		
		// Grab the current error and error code
		Handle(Error_CurrentError: -ErrorCode);

			// $DLErrorCode and $DLErrorMsg are not used for anything right now, but might be useful later.
			Var:'DLErrorCode' = (Error_CurrentError: -ErrorCode);
			Var:'DLErrorMsg' = (Error_CurrentError);
			Debug;
				'94: <strong>DLErrorCode</strong> =' $DLErrorCode '<br>\r';
				'94: <strong>DLErrorMsg</strong> =' $DLErrorMsg '<br>\r';
			/Debug;

			// Check for various error conditions. A valid file contains "JFIF". If found we then assume is a valid file.
			// Also look for "could not resolve", which indicates that Lasso's DNS lookup has gone deaf
			// If Lasso has gone deaf, you will see something like this:
			/* Error Number: -9953
			Error Message: Error from libcurl in tag: Include_URL - 6 - could not resolve host at: Include_URL with params: @'http://webthumb.bluga.net/easythumb.php?user=6291&..., -timeout=0 at: easythumb with params:  -url='http://devel.landmanninteractive.com/admin/preview...,  */
			If(($DLErrorMsg !>> 'JFIF') || ($DLErrorMsg >> 'could not resolve'));
			
				// Error_SetErrorMessage( 'it_easythumb Error: '+string(#response));
		
				// Set error 7027 "Thumnbnail generation failed"
				$vError = '7027';
				If($CheckValid !>> 'JFIF');
					$vOption = 'EasyThumb service unavailable.';
				Else($CheckValid >> 'Unable to resolve');
					$vOption = 'DNS lookup problem.';
				/If;
			
			// Conversion is probably OK, set Error_NoError
			Else;

				Error_CurrentError = Error_NoError;
				$vError = null;
				$vOption = null;

			/If;

		/Handle;

	/Protect;

	// Check for error
	If($vError == '7027');

		// Send e-mail to developer
		If($svDebug == 'Y');
			Var('Subject' = (($svDomain)+'Thumbnail Creation Failure DEBUG ON'));
		Else;
			Var('Subject' = (($svDomain)+'Thumbnail Creation Failure'));
		/If;
		Var('Body' = ('Thumbnail creation failed at '+(Server_Date)+' '+(Server_Time)'

The error was: ' ($vError) ' -- ' ($vOption)'

EasyThumb command used:  "'(#string_url)'"'));

		Email_Send(
			-Host=$svSMTP,
			-From=$svAdminEmail,
			-To=$svDeveloperEmail,
			-Subject=$Subject,
			-Username=$svAuthUsername,
			-Password=$svAuthPassword,
			-Sender=(($svDomain)+':it_easythumb.inc'),
			-Body=$Body);
	
	else;		

		#result += '<img src="';
			
		if: local_defined('file');
		
			//  Change this to add a record to a database, if desired
/*			Inline(	-Update, -Username='xxxxxxxxx', -Password='xxxxxxxxx', -Database='db', -Table='table',
				-KeyValue=local('content_keyvalue'),
				'img_path_field'= 'thumb_'+field('id')+'.jpg',
				-NoValueLists);
*/					
					error_code != '0'  ?  error_currenterror;
					file_write(#file, #response, -fileoverwrite);
					
//			/Inline;

			#result += ((#file)+('" '));
			
		else;
		
			#result += ((#string_url)+('" '));
			
		/if;
		
		select(#size);
			case('small'); #result += 'width="80" height="60" ';
			case('medium'); #result += 'width="160" height="120" ';
			case('medium2'); #result += 'width="320" height="240" ';
		/select;	
		!local_defined('id')? #result += 'id="'local('id')'" ';
		!local_defined('class')? #result += 'class="'local('class')'" ';
		
		#result += '/><br/><b>Preview successfully created!</b><br/>\n';

		// Set error code 7026 "Thumbnail Generation Successful"
		$vError = '7026';

	/If;

	// Debug option -- print out params
	local_defined('debug')? 
	#result +='-file='local('file')'<br/>
	-userid= '#userid'<br/>
	-size='#size'<br/>
	-content_keyvalue='local('content_keyvalue')'<br/>
	-url='#url'<br/>
	-apikey='#apikey'<br/>
	URL = '#string_url'<br/>'error_currenterror' 'file_currenterror;	
		
	error_code != '0'  ? #result += (error_currenterror' 'file_currenterror);

	Return(#result);

/define_tag;

Log_Critical: 'Custom Tag Loaded - it_easythumb';

?>