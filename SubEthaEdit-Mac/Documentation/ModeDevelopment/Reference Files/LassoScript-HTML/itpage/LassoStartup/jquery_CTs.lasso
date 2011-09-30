<?Lassoscript
// Last modified 4/24/08 by ECL, Landmann InterActive
/*
Tagdocs;
	{Tagname=			jquery_install }
	{Description=		This file defines a number of helper functions which automatically install the elements which are required for JQuery into the head of the current document. }
	{Author=			Lassosoft }
	{AuthorEmail=		}
	{ModifiedBy=		Eric Landmann }
	{ModifiedByEmail=	}
	{Date=				4/28/2008 }
	{Usage=				jquery_install }
	{ExpectedResults=	Modified HTML with the jQuery scripts installed }
	{Dependencies=		}
	{DevelNotes=		STATUS: UNUSED in itPage, but this tag is the model for the LI_CMSatend CT.
						See this tip of the week for descriptions of the custom tags defined in this file. http://www.lassosoft.com/Documentation/TotW/index.lasso?9302 }
	{ChangeNotes=		 }
/Tagdocs;
*/
	define_tag: 'jquery_install', -optional='immediate', -optional='nopack', -optional='module';

		!(var_defined: '__jquery_scripts__') ? var: '__jquery_scripts__' = array;
		!(var_defined: '__jquery_css__') ? var: '__jquery_css__' = array;
		!(var_defined: '__jquery_ready__') ? var: '__jquery_ready__' = array;
		
		if: (local_defined: 'immediate');
			local: 'head_regexp' = (regexp: -find='(\\s+)</head>', -input=$__html_reply__, -ignorecase);
			if: #head_regexp->find == true;
				local: 'prefix' = #head_regexp->(matchstring: 1);
				local: 'indent' = (#prefix->(endswith: '\t') ? '\t' | '');
				local: 'lines' = array;
				iterate: $__jquery_scripts__, (local: 'temp');
					if: $__html_reply__ !>> (regexp: -find='<head>.*' + #temp->second + '.*</head>');
						#lines->(insert: '<script type="text/javascript" src="' + #temp->second + '"></script>');
					/if;
				/iterate;
				if: $__jquery_ready__->size > 0;
					#lines->(insert: '<script type="text/javascript">$(document).ready(function() {' + #prefix + (#indent * 2) + $__jquery_ready__->(join: #prefix + (#indent * 2)) + #prefix + #indent + '});</script>');
				/if;
				if: $__jquery_css__->size > 0;
					#lines->(insert: '<style type="text/css">' + #prefix + (#indent * 2) + $__jquery_css__->(join: #prefix + (#indent * 2)) + #prefix + #indent + '</style>');
				/if;
				#head_regexp->(replacepattern: #prefix + #indent + #lines->(join: #prefix + #indent) + #prefix + '</head>');
				$__html_reply__ = #head_regexp->(replacefirst);
			else;
				log_warning: 'JQuery - Could not install script, no head element';
			/if;
		else;
			if: $__jquery_scripts__ !>> 'jquery';
				if: (local_defined: 'nopack') && (#nopack !== false);
					$__jquery_scripts__->(insert: 'jquery' = (jquery_filename: -nopack));
				else;
					$__jquery_scripts__->(insert: 'jquery' = (jquery_filename));
				/if;
			/if;
			loop: -from=$_at_end->size, -to=1, -by=-1;
				if: $_at_end->(get: loop_count)->(isa: 'pair') && $_at_end->(get: loop_count)->first == \jquery_install;
					$_at_end->(remove: loop_count);
				/if;
			/loop;
			define_atend: \jquery_install = (array: -immediate);

		/if;

	/define_tag;
	// Log tag loading
	Log_Critical: 'Custom Tag Loaded - jquery_install';
	
	define_tag: 'jquery_addscript', -required='script';
		!(var_defined: '__jquery_scripts__') ? var: '__jquery_scripts__' = array;
		if: $__jquery_scripts__ !>> #script;
			$__jquery_scripts__->(insert: #script = #script);
		/if;
	/define_tag;
	// Log tag loading
	Log_Critical: 'Custom Tag Loaded - jquery_addscript';
		
	define_tag: 'jquery_addcss', -required='style';
		!(var_defined: '__jquery_css__') ? var: '__jquery_css__' = array;
		$__jquery_css__->(insert: #style);
	/define_tag;
	// Log tag loading
	Log_Critical: 'Custom Tag Loaded - jquery_addcss';
	
	define_tag: 'jquery_addready', -required='script';
		!(var_defined: '__jquery_ready__') ? var: '__jquery_ready__' = array;
		$__jquery_ready__->(insert: #script);
	/define_tag;
	// Log tag loading
	Log_Critical: 'Custom Tag Loaded - jquery_addready';
	
	define_tag: 'jquery_filename', -optional='nopack';
		local: 'jquery_filenames' = array;
		local: 'pack_filenames' = array;
		local: 'jquery_regexp' = (regexp: '^jquery-([0-9\\.]+)(:?\\.pack)\\.js$');
		if: !(var_defined: '__jquery_directory__');
			var: '__jquery_directory__' = (file_listdirectory: '/site/js/');
		/if;
		iterate: $__jquery_directory__, (local: 'temp');
			if: #jquery_regexp->input(#temp) & find;
				local: 'insert' = (pair: (decimal: '0.' + #jquery_regexp->matchstring(1)->(replace: '.', '') &) = '/site/js/' + #temp);
				if: #temp >> 'pack.js';
					#pack_filenames->(insert: #insert);
				else;
					#jquery_filenames->(insert: #insert);
				/if;
			/if;
		/iterate;
		if:(((local_defined: 'nopack') == false) || (#nopack === false)) && (#pack_filenames->size > 0);
			return: (#pack_filenames->sort & last)->second;
		else;
			return: (#jquery_filenames->sort & last)->second;
		/if;
	/define_tag;
	// Log tag loading
	Log_Critical: 'Custom Tag Loaded - jquery_filename';

?>
