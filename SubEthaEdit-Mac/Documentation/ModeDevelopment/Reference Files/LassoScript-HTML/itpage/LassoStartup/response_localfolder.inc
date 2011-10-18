[//lasso
/*----------------------------------------------------------------------------

[response_localfolder]
Returns the absolute path to the current directory.

Author: Jason Huck
Last Modified: Jan. 01, 0001
License: 

Description:
Returns the absolute path to the current directory.


Sample Usage:
response_localfolder;

Downloaded from tagSwap.net on Aug. 21, 2009.
Latest version available from <http://tagSwap.net/response_localfolder>.

----------------------------------------------------------------------------*/
		

define_tag(
	'localfolder',
	-namespace='response_',
	-priority='replace',
	-description='Returns the absolute path to the current directory.'
);
	local('out') = response_localpath;
	local('file') = #out->split('/')->last;
	#out->removetrailing(#file);
	return(#out);

	Log_Critical: 'Custom Tag Loaded - Response_LocalFolder';

/define_tag;
]
