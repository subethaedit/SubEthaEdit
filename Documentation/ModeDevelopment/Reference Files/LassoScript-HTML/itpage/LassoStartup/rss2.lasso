[//lasso
/*----------------------------------------------------------------------------

[rss2]
Data types for creating RSS2 feeds. Based on [xml_tree].

Author: Jason Huck
Last Modified: Jan. 01, 0001
License: Public Domain

Description:
original specification are available as parameters except for the PICS rating. 
Both types will validate your input whenever possible and return an 
appropriate error message. The sample usage below demonstrates how different 
values should be passed.


Sample Usage:
var('myitem') = rss2_item(
	-title='This is a test item.',
	-link='http://www.somewhere.com/articles/testitem.html',
	-description='This is a description of the test item.',
	-author='user@domain.com (Joe Schmoe)',
	-category=pair('foo'='bar'),
	-comments='http://www.somewhere.com/articles/testitem_comments.html',
	-enclosure=map(
		'url' = 'http://www.somewhere.com/articles/testitem.mp3',
		'length' = 123456,
		'type' = 'audio/mpeg'
	),
	-guid='http://www.somewhere.com/articles/testitem.html',
	-pubDate=date,
	-source=pair('http://www.somewhere.com/articles/'='Somewhere.com Articles')
);

var('items') = array($myitem);

var('myfeed') = rss2(
	-title='My Test Feed',
	-link=client_url,
	-description='This is a description of my test feed.',
	-language='en-us',
	-copyright='2008 Somebody.',
	-managingEditor='user@domain.com (Joe Schmoe)',
	-webMaster='user@domain.com (Joe Schmoe)',
	-pubDate=date,
	-lastBuildDate=date,
	-category=pair('foo'='bar'),
	-generator='Lasso 8.5.5',
	-docs='http://blogs.law.harvard.edu/tech/rss',
	-cloud=map(
		'domain' = 'rpc.somewhere.com',
		'port' = 80,
		'path' = '/RPC2',
		'registerProcedure' = 'pingMe',
		'protocol' = 'SOAP'
	),
	-ttl=60,
	-image=map(
		'url' = 'http://www.somewhere.com/logo.png',
		'title' = 'My Test Feed',
		'link' = client_url,
		'width' = 60,
		'height' = 60,
		'description' = 'Visit Somewhere.com'
	),
	-skipHours=array(1,2,3,4,5),
	-skipDays=array('Monday','Wednesday','Friday'),
	-items=$items
);

content_type('text/xml;charset=utf-8');
$myfeed;


Downloaded from tagSwap.net on Nov. 27, 2009.
Latest version available from <http://tagSwap.net/rss2>.

----------------------------------------------------------------------------*/
		

define_type(
	'rss2',
	-description='Extends [xml_tree] specifically for the RSS2 format.'
);
	local('data' = xml_tree);

	define_tag(
		'onCreate',
		-req='title',
		-req='link',
		-req='description',
		-opt='language',
		-opt='copyright',
		-opt='managingEditor',
		-opt='webMaster',
		-opt='pubDate', -type='date',
		-opt='lastBuildDate', -type='date',
		-opt='category',
		-opt='generator',
		-opt='docs',
		-opt='cloud', -type='map',
		-opt='ttl', -type='integer',
		-opt='image', -type='map', -copy,
		-opt='rating',
		-opt='textInput', -type='map',
		-opt='skipHours', -type='array',
		-opt='skipDays', -type='array',		
		-opt='items'
	);
		self->'data'->setname('rss');
		self->'data'->addattribute('version'='2.0');
		self->'data'->addnamespace('atom'='http://www.w3.org/2005/Atom');
		self->'data'->newchild('channel');
		
		self->'data'->channel->newchild('atom:link');
		self->'data'->channel->getnode('atom:link')->addattribute('rel'='self');
		self->'data'->channel->getnode('atom:link')->addattribute('type'='application/rss+xml');
		self->'data'->channel->getnode('atom:link')->addattribute('href'=#link);
		
		// validation & defaults
		fail_if(
			!valid_url(#link),
			-1, 'The "link" element must be a valid URL.'
		);
		
		fail_if(
			local_defined('docs') && !valid_url(#docs),
			-1, 'The "docs" element must be a valid URL.'
		);
		
		if(local_defined('image'));
			local('reqd') = (: 'url', 'title', 'link');
			local('missing') = array;
			
			iterate(#reqd, local('i'));
				!#image->find(#i) || #image->find(#i) == '' ? #missing->insert(#i);
			/iterate;
			
			fail_if(
				#missing->size,
				-1, 'The "image" element is missing the following required values: ' + #missing->join(',') + '.'
			);
		
			fail_if(
				!valid_url(#image->find('url')),
				-1, 'The image URL provided is not valid.'
			);
			
			fail_if(
				(: 'gif', 'jpeg', 'jpg', 'png') !>> #image->find('url')->trim&split('.')->last,
				-1, 'The image URL does not point to a GIF, JPEG, or PNG image.'
			);
			
			if(integer(#image->find('width')));
				integer(#image->find('width')) > 144 ? #image->find('width') = 144;
			else;
				#image->insert('width' = 88);
			/if;

			if(integer(#image->find('height')));
				integer(#image->find('height')) > 400 ? #image->find('height') = 400;
			else;
				#image->insert('height' = 31);
			/if;
		/if;
		
		if(local_defined('textInput'));
			local('reqd') = (: 'title', 'description', 'name', 'link');

			local('missing') = array;
			
			iterate(#reqd, local('i'));
				!#textInput->find(#i) || #textInput->find(#i) == '' ? #missing->insert(#i);
			/iterate;
			
			fail_if(
				#missing->size,
				-1, 'The "textInput" element is missing the following required values: ' + #missing->join(',') + '.'
			);
			
			fail_if(
				!valid_url(#textInput->find('link')),
				-1, 'The URL value of the "textInput" element is not valid.'
			);
		/if;
		
		if(local_defined('skipHours'));
			fail_if(
				#skipHours->size > 24,
				-1, 'The "skipHours" element may not contain more than 24 items.'
			);
		
			iterate(#skipHours, local('i'));
				!#i->isa('integer') || #i < 0 || #i > 23 ? fail( -1, 'The "skipHours" element contains invalid values.');
			/iterate;
		/if;

		if(local_defined('skipDays'));
			fail_if(
				#skipDays->size > 7,
				-1, 'The "skipDays" element may not contain more than 7 items.'
			);
		
			local('days') = array(
				'Monday',
				'Tuesday',
				'Wednesday',
				'Thursday',
				'Friday',
				'Saturday',
				'Sunday'
			);
		
			iterate(#skipDays, local('i'));
				#days !>> #i ? fail( -1, 'The "skipDays" element contains invalid values.');
			/iterate;
		/if;
		
		// handle simple nodes for the channel
		local('simpleNodes') = array(
			'title',
			'link',
			'description',
			'language',
			'copyright',
			'managingEditor',
			'webMaster',
			'generator',
			'docs',
			'rating',
			'ttl'
		);
		
		iterate(#simpleNodes, local('i'));
			if(local_defined(#i));
				self->'data'->channel->newchild(#i);
				self->'data'->channel->getnode(#i)->addcontent(local(#i));
			/if;
		/iterate;

		// all other nodes require special handling

		// date nodes (convert to GMT)
		iterate((: 'pubDate', 'lastBuildDate'), local('i'));
			if(local_defined(#i));
				self->'data'->channel->newchild(#i);
				// Wed, 15 Jun 2005 19:00:00 GMT
				self->'data'->channel->getnode(#i)->addcontent(date_localtogmt(local(#i))->format('%a, %d %b %Y %H:%M:%S GMT'));
			/if;
		/iterate;

		// category
		if(local_defined('category'));
			self->'data'->channel->newchild('category');
			if(#category->isa('pair'));
				self->'data'->channel->category->addattribute('domain' = #category->first);
				self->'data'->channel->category->addcontent(#category->second);
			else;
				self->'data'->channel->category->addcontent(#category);
			/if;
		/if;
		
		// cloud
		if(local_defined('cloud'));
			self->'data'->channel->newchild('cloud');
			
			iterate(#cloud->keys, local('i'));
				self->'data'->channel->cloud->addattribute(#i = #cloud->find(#i));
			/iterate;
		/if;

		// image
		if(local_defined('image'));
			self->'data'->channel->newchild('image');
			
			iterate(#image->keys, local('i'));
				self->'data'->channel->image->newchild(#i);
				self->'data'->channel->image->getnode(#i, -count=1)->addcontent(#image->find(#i));
			/iterate;
		/if;

		// textInput
		if(local_defined('textInput'));
			self->'data'->channel->newchild('textInput');
			
			iterate(#textInput->keys, local('i'));
				self->'data'->channel->textInput->newchild(#i);
				self->'data'->channel->textInput->getnode(#i, -count=1)->addcontent(#textInput->find(#i));
			/iterate;
		/if;

		// skipHours
		if(local_defined('skipHours'));
			self->'data'->channel->newchild('skipHours');
			
			iterate(#skipHours, local('i'));
				self->'data'->channel->skipHours->newchild('hour');
				self->'data'->channel->skipHours->hour(loop_count)->addcontent(#i);
			/iterate;
		/if;

		// skipDays
		if(local_defined('skipDays'));
			self->'data'->channel->newchild('skipDays');
			
			iterate(#skipDays, local('i'));
				self->'data'->channel->skipDays->newchild('day');
				self->'data'->channel->skipDays->day(loop_count)->addcontent(#i);
			/iterate;
		/if;

		// items			
		if(local_defined('items'));
			iterate(#items, local('i'));
				self->'data'->channel->addchild(xml(#i));
			/iterate;
		/if;
	/define_tag;
	
	define_tag('_unknownTag');
		return(self->'data'->tag_name);
	/define_tag;
	
	define_tag('onConvert');
		return(string(self->'data'));
	/define_tag;
/define_type;



define_type(
	'item',
	-namespace='rss2_',
	-description='Generates XML for an RSS2 item node.'
);
	local('data' = xml_tree);
	
	define_tag(
		'onCreate',
		-opt='title',
		-opt='link',
		-opt='description',
		-opt='author',
		-opt='category',
		-opt='comments',
		-opt='enclosure', -type='map',
		-opt='guid',
		-opt='pubDate', -type='date',
		-opt='source'
	);
		fail_if(
			!local_defined('title') && !local_defined('description'), -1,
			'Either "title" or "description" must be specified.'
		);
	
		local('urls') = (: 'link', 'comments', 'guid');
	
		iterate(#urls, local('i'));
			fail_if(
				local_defined(#i) && !valid_url(local(#i)),
				-1, 'The "' + #i + '" element is not a valid URL.'
			);
		/iterate;
		
		if(local_defined('enclosure'));
			local('reqd') = (: 'url', 'length', 'type');
			local('missing') = array;
			
			iterate(#reqd, local('i'));
				#enclosure->find(#i) == '' ? #missing->insert(#i);
			/iterate;
			
			fail_if(
				#missing->size,
				-1, 'The "enclosure" element is missing required values: ' + #missing->join(',') + '.'
			);
			
			fail_if(
				!valid_url(#enclosure->find('url')),
				-1, 'The enclosure URL is not valid.'
			);
		/if;
	
		self->'data'->setname('item');
		
		iterate((:'title', 'link', 'description', 'author', 'comments', 'guid'), local('i'));
			if(local_defined(#i));
				self->'data'->newchild(#i);
				self->'data'->getnode(#i)->addcontent(local(#i));
			/if;
		/iterate;

		// category
		if(local_defined('category'));
			self->'data'->newchild('category');
			
			if(#category->isa('pair')); 
				self->'data'->category->addattribute('domain' = #category->first);
				self->'data'->category->addcontent(#category->second);
			else;
				self->'data'->category->addcontent(#category);
			/if;
		/if;
		
		if(local_defined('pubDate'));
			self->'data'->newchild('pubDate');
			// Wed, 15 Jun 2005 19:00:00 GMT
			self->'data'->pubDate->addcontent(date_localtogmt(#pubDate)->format('%a, %d %b %Y %H:%M:%S GMT'));
		/if;
		
		if(local_defined('enclosure'));
			self->'data'->newchild('enclosure');
			self->'data'->enclosure->addattribute('url'=#enclosure->find('url'));
			self->'data'->enclosure->addattribute('length'=#enclosure->find('length'));
			self->'data'->enclosure->addattribute('type'=#enclosure->find('type'));
		/if;
		
		if(local_defined('source'));
			self->'data'->newchild('source');
			self->'data'->source->addattribute('url' = #source->first);
			self->'data'->source->addcontent(#source->second);
		/if;
		
		// convert to xml type when finished to work around inheritance bugs
		self->'data' = xml(self->'data');
	/define_tag;

	define_tag('_unknownTag');
		return(self->'data'->tag_name);
	/define_tag;
	
	define_tag('onConvert');
		return(string(self->'data'));
	/define_tag;
/define_type;
]
