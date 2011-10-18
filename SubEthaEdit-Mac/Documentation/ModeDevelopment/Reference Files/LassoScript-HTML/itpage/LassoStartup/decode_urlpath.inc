[//lasso
/*----------------------------------------------------------------------------

[decode_urlpath]
Decodes a string encoded by [encode_urlpath].

Author: Jason Huck
Last Modified: Mar. 22, 2006
License: 

Description:
Decodes a string encoded by [encode_urlpath].


Sample Usage:
decode_urlpath($string);

Downloaded from tagSwap.net on Oct. 13, 2007.
Latest version available from <http://tagSwap.net/decode_urlpath>.

CHANGE NOTES
Modified by ECL on 10/14/07
Got rid of conversion from / to -!
Replacing spaces with dashes
----------------------------------------------------------------------------*/
		

define_tag(
	'urlpath',
	-namespace='decode_',
	-required='in',
	-priority='replace',
	-description='Decodes a string encoded by [encode_urlpath].'
);
	local('out') = #in;
	#out->replace('-',' ')&replace('&#92;','%5c')&replace('&#46;','.');
	#out = decode_url(#out);
//	#out->replace('-!','/')&replace('`','\'');
	#out->replace('//','/')&replace('`','\'');
	return(@#out);

	Log_Critical: 'Custom Tag Loaded - Decode_URLPath';

/define_tag;
]
