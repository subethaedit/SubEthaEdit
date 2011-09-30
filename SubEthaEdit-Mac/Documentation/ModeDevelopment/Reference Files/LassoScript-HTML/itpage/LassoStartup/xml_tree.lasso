[//lasso
/*----------------------------------------------------------------------------

[xml_tree]
Extends and simplifies the built-in XML type.

Author: Jason Huck
Last Modified: Aug. 30, 2009
License: Public Domain

Description:
built-in XML type, making it easier to retrieve values from XML documents when 
the structure is known. It adds the following new member tags:
 
 ->atts - Returns a map of the attributes for the current node, instead of an 
array of pairs.
 
 ->attribute(string) - Returns the value of the given attribute for the 
current node.
 
 ->nodename(index) - Returns the given child node by name. If there are 
multiple nodes of the same name, you can return a specific node by passing an 
index. If no matching child nodes are found, it will look for an attribute by 
that name.
 
 ->getnode(string) - Same as ->nodename above. Useful if the node name 
conflicts with an existing member tag, such as "name."
 
 ->getnodes - Returns the children of the current node, minus the empty ones 
that ->children generates on its own.


Sample Usage:
var('testxml') = '\
<?xml version="1.0" ?>
<root>
	<record>
		<thing foo="bar">blah</thing>
		<thing foo="meow">moo</thing>
	</record>
</root>';

var('test') = xml_tree($testxml);

$test->record->thing(2)->contents;

-> moo




Downloaded from tagSwap.net on Nov. 27, 2009.
Latest version available from <http://tagSwap.net/xml_tree>.

----------------------------------------------------------------------------*/
		

define_type(
	'tree', 'xml',
	-namespace='xml_',
	-description='Extends and simplifies the built-in XML type.'
);
	define_tag('atts');
		local('out' = map);
		
		iterate(self->attributes, local('i'));
			#out->insert(@#i->first = @#i->second);
		/iterate;
		
		return(@#out);
	/define_tag;
	
	define_tag('attribute', -req='name');
		if(self->attributes->size && self->attributes->find(#name)->size);
			return(@self->attributes->find(#name)->first->second);
		else;
			return('');
		/if;
	/define_tag;
	
	define_tag('getNode', -req='nodename', -opt='count');
		local('matches') = @self->extract('*[translate(local-name(), \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\') = translate(\'' + #nodename + '\', \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\')]');
		
		if(!#matches->size);
			return(@self->attribute(#nodename));
		else(#matches->size == 1);
			return(@#matches->first);
		else;
			if(local_defined('count'));
				protect;
					return(@#matches->get(integer(#count)));
					
					handle_error;
						return;
					/handle_error;
				/protect;
			else;
				return(@#matches);
			/if;
		/if;
	/define_tag;
	
	define_tag('getnodes');
		local('out') = self->children;
		// remove any element that contains only whitespace
		#out->removeall(match_notregexp('\\S'));
		return(@#out);
	/define_tag;
	
	define_tag('_unknowntag');
		if(params->size);
			return(@self->getnode(tag_name, @params->first));
		else;
			return(@self->getnode(tag_name));
		/if;
	/define_tag;
/define_type;
]
