[//lasso
/*----------------------------------------------------------------------------

[shell]
Executes commands in a shell.

Author: Jason Huck
Last Modified: Aug. 27, 2008
License: Public Domain

Description:
[os_process] type that allows you to interact with a bash shell, similar to 
how you would if you were using Terminal on OS X. On Windows, it interacts 
with the cmd process. The tag creates a new [os_process] type, opens a new 
shell, switches the current working directory to the folder from which the tag 
was called, and executes whatever command is passed to it. Requires 
[response_localfolder] and only loads if the [os_process] type is loaded.


Sample Usage:
shell('echo foo');

-> foo


Downloaded from tagSwap.net on Aug. 21, 2009.
Latest version available from <http://tagSwap.net/shell>.

----------------------------------------------------------------------------*/
		

if(lasso_tagexists('os_process'));
	define_tag(
		'shell',
		-required='cmd',
		-privileged,
		-priority='replace',
		-description='Executes a single shell command via [os_process].'
	);
		local('os') = lasso_version( -lassoplatform);
	
		if(#os >> 'Win');
			local('shell') = os_process(
				'cmd',
				(: '/c cd ' + response_localfolder + ' && ' + #cmd)
			);		
		else;
			local('shell') = os_process(
				'/bin/bash',
				(: '-c', 'cd ' + response_localfolder + '; ' + #cmd)
			);
		/if;
		
		local('out') = #shell->read;
		!#out->size ? #out = #shell->readerror;
		#shell->close;
		return(#out);
	/define_tag;

	Log_Critical: 'Custom Tag Loaded - Shell';

/if;
]
