<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			OutputPortfolio }
	{Description=		Outputs the already-built $PortfolioContent }
	{Author=			Eric Landmann }
	{AuthorEmail=		support@iterate.ws }
	{ModifiedBy=		 }
	{ModifiedByEmail=	 }
	{Date=				3/18/08 }
	{Usage=				OutputPortfolio: -Columns='5' }
	{ExpectedResults=	Outputs the HTML in $PortfolioContent in an HTML table }
	{Dependencies=		$PortfolioContent must be defined, otherwise there will be no output
						$portfolio_thumb_array is a copy of the Records_Array from a search on Portfolio Entries }
	{DevelNotes=		$PortfolioContent is created in detail.inc.
						This tag is merely a convenience to make it less awkward for a designer
						It outputs the portfolio in ***one large block***, there is no pagination available.
						Columns is the number of columns displayed in the portfolio.
						Rows are automatically calculated and displayed. }
	{ChangeNotes=		8/31/09
						Integrated into itPage codebase. }
/Tagdocs;
*/
If: !(Lasso_TagExists:'OutputPortfolio');
	Define_Tag:'OutputPortfolio',
		-Description='Outputs $PortfolioContent, which contains the left nav content for the LI CMS 3.0',
		-Required = 'Columns',
		-Priority = 'replace';

		Local:'Result' = null;
		Local:'column_limit' = integer;
		Local:'column_counter' = 0;
		Local:'ThisPosition' = integer;

		// Copy columns to column_limit to use in calculations
		// Column_limit is the number of columns displayed in the portfolio
		#column_limit = #columns;

		// Check if $PortfolioContent is defined
		If: (Var_Defined:'PortfolioContent');

//			#Result += '\t<h3 class="PortfolioImage">Portfolio</h3>\n';
			If: $svDebug == 'Y';
				#Result += '<p class="debugCT">\n';
				#Result += '60: portfolio_thumb_array = ' ($portfolio_thumb_array) '</p>\n';
			/If;
			#Result += '<!-- START Output Portfolio -->\n';
			#Result += '<table width="100%">\n';
			#Result += '\t<tr>\n';
			#column_counter = 0;
			Loop: ($portfolio_thumb_array->size);
				#column_counter = (Math_Add: #column_counter, 1);
				#Result += '\t\t<td valign="top">\n';
				#Result += '\t\t\t<div class="PortfolioImage">\n';
				Protect;
					Local:'ThisPosition' = ($portfolio_thumb_array->(Get:(Loop_Count)));
					Local:'ThisPosition_PortfolioID' = (#ThisPosition->Get:1);
					Local:'ThisPosition_PortfolioTitle' = (#ThisPosition->Get:2);
					Local:'ThisPosition_PortfolioCaption' = (#ThisPosition->Get:3);
					Local:'ThisPosition_PortfolioURL' = (#ThisPosition->Get:4);
					Local:'ThisPosition_PortfolioThumb' = (#ThisPosition->Get:5);
					If: #ThisPosition_PortfolioTitle != '';
						#Result += '\t\t\t\t<div class="PortfolioTitle">'(#ThisPosition_PortfolioTitle)'</div>\n';
					/If;
					If: #ThisPosition_PortfolioURL != '';
						#Result += '\t\t\t<a href="'(#ThisPosition_PortfolioURL)'" target="_blank">';
					Else;
						#Result += '\t\t\t<a href="'($svImagesLrgPath)(#ThisPosition_PortfolioThumb)'" target="_blank">';
					/If;
					#Result += '<img src="'($svImagesThmbPath)(#ThisPosition_PortfolioThumb)'" alt="'(#ThisPosition_PortfolioThumb)'"></a><br>\n';
					If: #ThisPosition_PortfolioCaption != '';
						#Result += '\t\t\t</div>\n';
						#Result += '\t\t\t<div class="PortfolioCaption">\n';
						#Result += '\t\t\t\t'(#ThisPosition_PortfolioCaption)'<br>\n';
					/If;
				/Protect;
				If: $svDebug == 'Y';
					#Result += '<p class="debugCT">\n';
					#Result += '143: ThisPosition = ' (#ThisPosition) '</p>\n';
				/If;
				#Result += '\t\t\t</div>\n';
				#Result += '\t\t</td>\n';
				// Add closing </tr> if end of column
				If: (#column_counter == #column_limit);
					#Result += '\t</tr><!-- 74 -->\n';
					#column_counter = 0;
					If: ((Loop_Count) != $ImageCount);
						#Result += '\t<tr><!-- 77 -->\n';
					/if;
				/if;
			/Loop;
			#Result += '\t</tr><!-- 80 -->\n';
			#Result += '\t<tr>\n';
			#Result += '\t\t<td valign="top" colspan="'(#column_limit)'" align="center">';
			// Navigation control
//			Include:($svLibsPath)'nav_control_grid.inc';
			#Result += '\t\t</td>\n';
			#Result += '\t</tr>\n';
			#Result += '</table>\n';
			#Result += '<!-- END Output Portfolio -->\n';

		Else;

			If: $svDebug == 'Y';
				#Result += 'Portfolio content is undefined<br>\n';
			/If;

		/If;

		Return: (Encode_Smart:(#Result));

	/Define_Tag;

	Log_Critical: 'Custom Tag Loaded - OutputPortfolio';

/If;
?>