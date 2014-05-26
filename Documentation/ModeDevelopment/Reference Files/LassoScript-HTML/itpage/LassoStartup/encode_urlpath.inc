[//lasso
/*----------------------------------------------------------------------------

[encode_urlpath]
Makes a string safe to use as a URL path component with Apache.

Author: Jason Huck
Last Modified: Mar. 22, 2006
License: 

Description:
This tag is part of a workaround for a security measure in Apache that 
complains about URL path components that contain URL-encoded slashes. Can be 
decoded using [decode_urlpath].

This tag is designed to be used with the [define_atbegin] method of URL 
rewriting. Since the regular expression commonly used in the <LocationMatch> 
directive with that method only passes virtual paths that do not contain 
periods, periods are also encoded. The tag also converts spaces to underscores 
for improved readability.


Sample Usage:
encode_urlpath($string);

Downloaded from tagSwap.net on Oct. 13, 2007.
Latest version available from <http://tagSwap.net/encode_urlpath>.

CHANGE NOTES
Modified by ECL on 10/14/07
Got rid of conversion from / to -!
Replacing spaces with dashes
----------------------------------------------------------------------------*/
		

define_tag(
	'urlpath',
	-namespace='encode_',
	-required='in',
	-priority='replace',
	-description='Makes a string safe to use as a URL path component with Apache.'
);		
	local('out') = #in;		
//	#out->replace(' ','_')&replace('/','-!')&replace('\'','`');
	#out->replace(' ','-');
	#out = encode_stricturl(#out);
	#out->replace('.','&#46;')&replace('%5c','&#92;');
	return(@#out);

	Log_Critical: 'Custom Tag Loaded - Encode_URLPath';

/define_tag;
]
