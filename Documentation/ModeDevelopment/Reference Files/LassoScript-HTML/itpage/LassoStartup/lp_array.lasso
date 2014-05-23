<?Lassoscript 
// Last modified 1/23/08 by ECL, Landmann InterActive

// Tagname			lp_array
// Description		[array] with additional member tags
// Author			Bil Corry
// Date				Installed 1/23/08 - last update to this tag unknown
// Notes			Part of the LassoPro Library

If:!(Lasso_TagExists:'lp_array');
define_type:'lp_array', 'array',
	-description='[array] with additional member tags.';
	local:'index' = 1;

	define_tag:'setindex',
		-required='index';
		if:(local:'index') == 'first';
			self->'index' = 1;
		else: (local:'index') == 'last';
			self->'index' = self->size;
		else: (integer: (local:'index')) < 1;
			fail: -1, 'Index value is too small.';
		else: (integer: (local:'index')) > self->size;
			fail: -1, 'Index value is too large.';		
		else;
			self->'index' = (integer: #index);
		/if;
	/define_tag;

	define_tag:'getindex';
		return: self->'index';
	/define_tag;

	define_tag:'roundrobin';
		if: self->size == 0;
			return: null;
		/if;
		if: self->'index' > self->size;
			self->'index' = self->size;
		/if;
		local:'temp' = self->(get: self->'index');
		self->'index' += 1;
		if: self->'index' > self->size;
			self->'index' = 1;
		/if;
		return: #temp;
	/define_tag;

	define_tag:'reverserobin';
		if: self->size == 0;
			return: null;
		/if;
		if: self->'index' > self->size;
			self->'index' = self->size;
		/if;
		local:'temp' = self->(get: self->'index');
		self->'index' -= 1;
		if: self->'index' < 1;
			self->'index' = self->size;
		/if;
		return: #temp;
	/define_tag;

	define_tag:'random';
		if: self->size == 0;
			return: null;
		/if;
		self->'index' = (math_random: -lower=1, -upper=self->size);
		return: self->(get: self->'index');
	/define_tag;

	define_tag:'popfirst';
		if: self->size == 0;
			fail: -1, 'Empty array.';
		/if;		
		local:'temp' = self->(get: 1);
		self->(remove: 1);
		return: #temp;
	/define_tag;

	define_tag:'poplast';
		if: self->size == 0;
			fail: -1, 'Empty array.';
		/if;		
		local:'temp' = self->(get: self->size);
		self->(remove: self->size);
		return: #temp;
	/define_tag;

	define_tag:'poprandom';
		if: self->size == 0;
			fail: -1, 'Empty array.';
		/if;
		local:'random' = (math_random: -lower=1, -upper=self->size);
		local:'temp' = self->(get: #random);
		self->(remove: #random);
		return: #temp;		
	/define_tag;

	define_tag:'pushfirst',-required='item';
		self->(insertfirst: #item);
	/define_tag;
	
	define_tag:'pushlast',-required='item';
		self->(insertlast: #item);
	/define_tag;

	define_tag:'pushrandom',-required='item';
		// this is how we would do it if ctypes with parents worked properly
		// self->(insert: #item, (math_random: -lower=1, -upper=self->size + 1));
		//
		// but it doesn't, so instead, we have to do the following...
		
		// save error so we won't overwrite it with our protect below
		local:'_ec' = error_code;
		local:'_em' = error_msg;
		lp_error_clearError;

		if: self->size == 0;
			self->(insert: #item);
		else;
			local:'random' = (math_random: -lower=1, -upper=self->size + 1);
			local:'temp' = array;
			loop: self->size + 1;
				if: loop_count == #random;
					#temp->(insert: #item);
				/if;

				protect;
					#temp->(insert: self->popfirst);
				/protect;
			/loop;
			iterate: #temp, local:'t';
				self->(insert: #t);
			/iterate;
		/if;

		// restore the error, if any
		error_code = #_ec;
		error_msg  = #_em;
	/define_tag;


	define_tag:'join',
		-optional='join',
		-optional='front',
		-optional='back',
		-optional='first',
		-optional='last';
		if: self->size == 0;
			return: null;
		/if;
		if: !local_defined:'join';
			local:'join' = '';
		/if;
		if: !local_defined:'front';
			local:'front' = '';
		/if;
		if: !local_defined:'back';
			local:'back' = '';
		/if;
		if: !local_defined:'first';
			local:'first' = #join;
		/if;
		if: !local_defined:'last';
			local:'last' = #join;
		/if;
			if: self->size == 1;
			return: #front (self->(get: 1)) #back;
		/if;
		if: self->size == 2;
			if: #last->size;
				return: #front (self->(get:1)) #last (self->(get:2)) #back;
			else: #first->size;
				return: #front (self->(get:1)) #first (self->(get:2)) #back;
			else;
				return: #front (self->(get:1)) #join (self->(get:2)) #back;
			/if;
		/if;
		local:'return' = #front;
		#return += self->(get:1);
		#return += #first;
		loop: -from=2, -to=self->size - 1;
			#return += self->(get:loop_count);
			#return += #join;
		/loop;
		#return->(removetrailing: #join);
		#return += #last;
		#return += self->(get:self->size);
		#return += #back;
		return: #return;
	/define_tag;

	define_tag:'keys';
		local:'keys' = array;
		iterate: self, local:'s';
			if: #s->type == 'pair';
				#keys->(insert: #s->name);
			/if;
		/iterate;
		return: #keys;
	/define_tag;

	define_tag:'values';
		local:'values' = array;
		iterate: self, local:'s';
			if: #s->type == 'pair';
				#values->(insert: #s->value);
			/if;
		/iterate;
		return: #values;
	/define_tag;

	define_tag:'removepair', -required='key';
		local:'pos' = self->(findposition: #key);
		while: #pos->size > 0;
			self->(remove: #pos->(get:1));
			#pos = self->(findposition: #key);
		/while;
	/define_tag;

	define_tag:'insertpair', -required='pair';
		if: #pair->type != 'pair';
			self->(removepair: #pair);
			self->(insert: (pair: #pair = null));
		else;
			self->(removepair: #pair->name);
			self->(insert: #pair);
		/if;
	/define_tag;

	define_tag:'findpair', -required='key';
		local:'findpair' = self->(findposition: #key);
		if: #findpair->size == 0;
			return: null;
		/if;
		#findpair = self->(get: #findpair->(get:1));
		if: #findpair->type == 'pair';
			return: #findpair->value;
		else;
			return: #findpair;
		/if;
	/define_tag;

	define_tag:'findvalue', -required='key'; // same as findpair
		local:'findpair' = self->(findposition: #key);
		if: #findpair->size == 0;
			return: null;
		/if;
		#findpair = self->(get: #findpair->(get:1));
		if: #findpair->type == 'pair';
			return: #findpair->value;
		else;
			return: #findpair;
		/if;
	/define_tag;

	define_tag:'findkeys', -required='value';
		local:'keys' = array;
		iterate: self, local:'s';
			if: #s->type == 'pair' && #s->value == #value;
				#keys->(insert: #s->name);
			/if;
		/iterate;
		return: #keys;
	/define_tag;

/define_type;

Log_Critical: 'Custom Tag Loaded - lp_array';

/If;

?>