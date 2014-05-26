<?Lassoscript
// Last modified 6/9/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			LI_CMSatend }
	{Description=		at-end handler for itPage }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				12/23/07 }
	{Usage=				 }
	{ExpectedResults=	Modifies the HTML of the page:
						1 - If a login page, adds JS at the end of the page to activate the login form
						2 - If a media file is assigned to the page, adds JS to the head if a Flash Video file is called	}
	{Dependencies=		Video variables:
						$ThisMediaFile = name of media file (located in /media)
						$VideoWidth = Video width
						$VideoHeight = Video height
						FlowPlayerLight.swf must be in the $svLibsPath
						The Flash Embed javascript is called from /site/js/flashembed.min.js
						A special media stylesheet is called at /site/css/media.css }
	{DevelNotes=		Original idea for this came from "An introduction to using JQuery with Lasso <http://www.lassosoft.com/Documentation/TotW/index.lasso?9302> }
	{ChangeNotes=		12/23/08
						First implementation of Video install code
						1/14/09
						Adding lookup for $DropdownJS to add content to <head>
						6/6/09
						Added a content_body->trim, Issue #876
						6/9/09
						Replaced $__html_reply__ with Content_Body }
/Tagdocs;
*/

Define_Tag: 'LI_CMSatend', -priority='Replace';

	local:'PageEnd_regexp' = (regexp: -find='(\\s+)</body>', -input=(Content_Body), -ignorecase);
	if: #PageEnd_regexp->find == true;
		local: 'prefix' = #PageEnd_regexp->(matchstring: 1);
		local: 'lines' = array;
		if: (Content_Body) >> (regexp: -find='LoginForm');
			#lines->(insert: '<!-- Inserted by LI_CMSatend -->');
			#lines->(insert: '<script language="JavaScript" type="text/javascript">');
			#lines->(insert: '\t<!-- Set focus to User_LoginID in login form -->');
			#lines->(insert: '\tdocument.LoginForm.User_LoginID.focus();');
			#lines->(insert: '</script>');
		/if;

		#PageEnd_regexp->(replacepattern: #prefix + #lines->(join: #prefix) + #prefix + '</body>');
		(Content_Body) = #PageEnd_regexp->(replacefirst);

	/if;

	// TESTING
	//	Var:'ThisMediaFile' = 'Shisha_9048EIceClimb_XWn.flv';
	//	Var:'VideoWidth' = 640;
	//	Var:'VideoHeight' = 480;

	// Don't need Media stylesheet on regular content pages
	// But if you did, here is the code
	// <link rel="stylesheet" type="text/css" href="/site/css/media.css">
	If: (Var:'VideoFilename') != '';

		// Create the output string to install
		local:'InstallThisJS' = ('<!-- Inserted by LI_CMSatend -->
		<script type="text/javascript" src="'($svJSPath)'flashembed.min.js"></script>
		<script>
			flashembed("VideoPlaceholder", 
			{
				src:\''($svLibsPath)'FlowPlayerLight.swf\',
				width: '(Var:'VideoWidth')',
				height: '(Var:'VideoHeight')'
			},
			{config: {   
				autoPlay: false,
				autoBuffering: true,
				controlBarBackgroundColor:\'#999999\',
				controlBarGloss:\'high\',
				showFullScreenButton: false,
				initialScale: \'scale\',
				loop: false,
				menuItems: [true, true, true, true, false, false, false],
				videoFile: \'http://'($svDomain)($svMediaPath)($VideoFilename)'\'
			}} 
		);
		</script>\n');
	
		// If VideoPlaceHolder found, do the substition
		// VideoPlaceHolder is inserted in build_detail.inc if a media file is found
		local:'head_regexp' = (regexp: -find='(\\s+)</head>', -input=(Content_Body), -ignorecase);
	
		if: #head_regexp->find == true;
	
			local: 'prefix' = #head_regexp->(matchstring: 1);
			local: 'lines' = array;
	
			if: (Content_Body) >> (regexp: -find='VideoPlaceholder');
				// (Content_Body) += ('77: FOUND IT<br>');
				#lines->(insert: #InstallThisJS);
			Else;
				// (Content_Body) += ('77: MISSED!<br>');
			/if;
			// (Content_Body) += ('79: #lines = '(#lines));
	
			#head_regexp->(replacepattern: #prefix + #lines->(join: #prefix) + #prefix + '</head>');
			(Content_Body) = #head_regexp->(replacefirst);
	
		Else;
			// Do nothing
		/If;

	/If;

	// 1/14/09
	// REMOVING THIS as it DOES NOT WORK ON detail.lasso

	// Adding lookup for $DropdownJS to add content to <head>
	// $DropdownJS is created by build_dropdownVars.inc,

/*	If: (Var:'DropdownJS') != '';

		// Create the output string to install
		local:'InstallThisDropdown' = $DropdownJS;

		// Use this code for Fireworks-style dropdowns that use mm_menu.js
		// #InstallThisDropdown += '<script language="JavaScript1.2" src="'($svJSPath)'mm_menu.js"></script>\n';

		local:'head_regexp' = (regexp: -find='(\\s+)</head>', -input=(Content_Body), -ignorecase);
	
		if: #head_regexp->find == true;
	
			local: 'prefix' = #head_regexp->(matchstring: 1);
			local: 'lines' = array;

			#lines->(insert: #InstallThisDropdown);
	
			#head_regexp->(replacepattern: #prefix + #lines->(join: #prefix) + #prefix + '</head>');
			(Content_Body) = #head_regexp->(replacefirst);

		Else;
			// Do nothing
		/If;

	/If;
*/
	// ALWAYS trim excess whitespace
	Content_Body->trim;

/Define_Tag;

Log_Critical: 'Custom Tag Loaded - LI_CMSatend';

?>