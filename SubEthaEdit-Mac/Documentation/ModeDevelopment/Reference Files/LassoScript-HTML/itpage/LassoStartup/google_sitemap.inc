[//lasso
/*----------------------------------------------------------------------------

[google_sitemap]
Creates Google sitemaps.

Author: Jason Huck
Last Modified: Jan. 01, 0001
License: 

Description:
This is a custom type for generating Google Sitemaps. It contains the 
following member tags:

->addurl - Used to add a URL node to the map. Per the API, accepts -loc, 
-lastmod, -changefreq, and -priority. Only -loc is required. For specific 
usage instructions, refer to the API reference.

->save - Saves a gzip-compressed copy of the map to the provided folder path 
with the name 'sitemap.gz'. Requires file tags permissions and the 
[compress_gzip] tag.

->output - Used internally, outputs an XML representation of the sitemap. The 
onConvert callback calls this tag.

->createnode - Used internally, converts a map of URL parameters into an xml 
node.


Sample Usage:
inline( -username='xxxxxx', -password='xxxxxx');
	var('mySiteMap') = google_sitemap;
	
	$mySiteMap->addurl(
		-loc='http://www.yahoo.com/blah.html?foo=bar&red=blue',
		-lastmod=date,
		-changefreq='always',
		-priority=1.0
	);
	
	$mySiteMap->save(response_path);
/inline;


Downloaded from tagSwap.net on Jun. 17, 2008.
Latest version available from <http://tagSwap.net/google_sitemap>.

----------------------------------------------------------------------------*/
		

define_type(
		'sitemap',
		-namespace='google_',
		-prototype,
		-description='Custom type for creating Google Sitemaps.'
	);
		local('urls' = array);		


		define_tag(
			'addurl',
			-req='loc', -type='string', -copy,
			-opt='lastmod', -type='date',
			-opt='changefreq', -type='string',
			-opt='priority', -type='decimal'
		);
			fail_if(
				(!valid_url(#loc) || #loc->size >= 2048),
				-1,
				'Location must be a valid URL and less than 2048 characters.'
			);
	
			#loc = encode_xml(decode_xml(#loc));	// avoid double encoding
						
			local_defined('lastmod') ? #lastmod->setformat('%Y-%m-%d');
			
			if(local_defined('changefreq'));
				local('freqs') = array(
					'always',
					'hourly',
					'daily',
					'weekly',
					'monthly',
					'yearly',
					'never'
				);
			
				#freqs !>> #changefreq ? #changefreq = null;
			else;
				local('changefreq' = null);
			/if;
			
			if(local_defined('priority'));
				select(true);
					case(#priority < 0.0);
						#priority = 0.0;
					case(#priority > 1.0);
						#priority = 1.0;
					case;
						#priority->setformat( -precision=1);
				/select;
			else;
				local('priority' = 0.5);
			/if;
			
			local('out' = map);
			#out->insert('loc' = #loc);
			#out->insert('lastmod' = #lastmod);
			#out->insert('changefreq' = #changefreq);
			#out->insert('priority' = #priority);
			
			self->urls->insert(#out);
		/define_tag;


		define_tag('createnode', -req='in');
			local('out') = xml('<url />');
			
			#out->newchild('loc')->addcontent(#in->find('loc'));
			#in->find('lastmod') != null ? #out->newchild('lastmod')->addcontent(#in->find('lastmod'));
			#in->find('changefreq') != '' ? #out->newchild('changefreq')->addcontent(#in->find('changefreq'));
			#out->newchild('priority')->addcontent(#in->find('priority'));
			
			return(@#out);
		/define_tag;

		
		define_tag('output');
			local('out') = xml('\
<urlset xmlns="http://www.google.com/schemas/sitemap/0.84"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.google.com/schemas/sitemap/0.84
	http://www.google.com/schemas/sitemap/0.84/sitemap.xsd" />
\			');
			
			iterate(self->urls, local('i'));
				#out->addchild(self->createnode(#i));
			/iterate;
			
			return('<?xml version="1.0" encoding="UTF-8"?>\n' + #out);
		/define_tag;
	
	
		define_tag('onConvert');
			return(@self->output);
		/define_tag;
	
	
		define_tag('save', -req='path');
			local('filepath' = #path);
			#filepath->removetrailing('/')&append('/sitemap.gz');
		
			file_write(
				#filepath,
				compress_gzip(self->output),
				-fileoverwrite
			);
		/define_tag;
	/define_type;
]
