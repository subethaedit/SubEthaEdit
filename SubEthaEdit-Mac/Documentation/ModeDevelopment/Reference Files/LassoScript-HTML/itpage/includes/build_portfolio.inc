<?Lassoscript
// Last modified 8/31/09 by ECL, Landmann InterActive

// CHANGE NOTES
// 1/6/08
// First implementation
// 8/31/09
// Changed order of records to ORDER BY pf.portfolio_id

/* ----------------------------------------- */
/* --- BUILD PORTFOLIO ----------------- */
/* ----------------------------------------- */
Var:'PortfolioContent' = (string);

// Initialize vars to display file matrix
Var:'portfolio_thumb_array' = array;
Var:'ImageCount' = integer;

// Initialize the vars to display the table
// var:'column_limit' = 5;
// var:'column_counter'= 0;

$PortfolioContent += '\n<!-- START build_portfolio -->\n';
/* SAMLE QUERY
SELECT pf.portfolio_id, pf.portfolio_title, pf.portfolio_caption, pf.portfolio_URL, pf.portfolio_thumb
FROM cms_portfoliogroups AS pg
LEFT JOIN cms_pg2portfolio
	USING (pg_groupid)
LEFT JOIN cms_portfolio AS pf
	USING (portfolio_id)
WHERE
pg.pg_groupid = 1 AND
pg.active = 'Y' AND
pf.active = 'Y'
ORDER BY pf.portfolio_caption
*/
	Var:'SQLBuildPortfolio' = '/* build_portfolio - $SQLBuildPortfolio */
		SELECT pf.portfolio_id, pf.portfolio_title, pf.portfolio_caption, pf.portfolio_URL, pf.portfolio_thumb
		FROM ' $svPortfolioGroupsTable ' AS pg
		LEFT JOIN ' $svPG2PortfolioTable '
			USING (pg_groupid)
		LEFT JOIN ' $svPortfolioTable ' AS pf
			USING (portfolio_id)
		WHERE
		pg.pg_groupid = ' $vPortfolioGroupID ' AND
		pg.active = "Y" AND
		pf.active = "Y"
		ORDER BY pf.portfolio_id';
	
	Inline: $IV_Portfolios, -SQL=$SQLBuildPortfolio;
		If: $svDebug == 'Y';
			$PortfolioContent += '<p class="debug">45: Found_Count = ' (Found_Count) '<br>\n';
			$PortfolioContent += '45: Error_CurrentError = ' (Error_CurrentError) '<br>\n';
			$PortfolioContent += '45: SQLBuildPortfolio = ' ($SQLBuildPortfolio) '</p>\n';
		/If;

		// Copy Records_Array to $portfolio_thumb_array. This will be used to display the portfolio
		$portfolio_thumb_array = (Records_Array);
		$ImageCount = ($portfolio_thumb_array->size);

		If: $svDebug == 'Y';
			$PortfolioContent += '<p class="debug">65: portfolio_thumb_array = ' ($portfolio_thumb_array) '</p>\n';
		/If;

	/Inline;

// END container for right navbar
$PortfolioContent += '<!-- END build_portfolio -->\n';

?>
