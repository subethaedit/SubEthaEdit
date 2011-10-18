<?Lassoscript
// Last modified on 9/6/07 by ECL, Landmann InterActive

// QuickSearch form, typically used in navbar

?><!-- START QuickSearch Form -->
<div class="quicksearch">
	<form action="/detail.lasso" class="quicksearch">
		<input type="hidden" name="SearchType" value="QS">
		<input type="text" style="width: 80px;" name="QuickSearchFor" value="[Var:'QuickSearchFor']" size="15">
		<input type="image" src="[$svImagesPath]button_search.gif" alt="Search Buttton" name="Action" value="QuickSearch" class="button">
	</form>
</div>
<!-- END QuickSearch Form -->
