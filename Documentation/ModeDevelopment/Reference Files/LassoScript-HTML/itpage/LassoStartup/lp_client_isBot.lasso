[

define_tag: 'lp_client_isBot',
	-description='Returns true if client is a bot, spider, validator, robot or crawler.',
	-priority='replace',
	-optional='user_agent', // test a user agent string
	-optional='deny',       // returns true when code matches, all else reported false
	-optional='allow',      // returns false when code matches, all else reported true
	-optional='strict',     // only return true for known bots
	-optional='loose';      // true for known bots and suspected bots and unknown clients

	if: local_defined:'user_agent';
		local:'client_browser' = #user_agent;
	else;
		local:'client_browser' = client_browser;
	/if;

	local:'typecode' = 'CDEFLORSVX'; // default

	if: local_defined:'strict';
		local:'typecode' = 'CDEFLORSV';
	else: local_defined:'loose';
		local:'typecode' = 'CDEFLORSUVX';
	else: local_defined:'deny';
		local:'typecode' = (string: #deny);
	else: local_defined:'allow';
		local:'typecode' = 'BCDEFLOPRSUVX';
		iterate: (string: #allow), local:'chr';
			#typecode->(remove: #typecode->(find: #chr), 1);
		/iterate;
	/if;

	return: #typecode->(contains: (lp_client_browser: #client_browser)->(find:'typecode'));

/define_tag;

]