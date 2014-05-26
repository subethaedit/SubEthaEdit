<?Lassoscript 
	// -----------------------------------------------------------
	/*	
		
		VERSION 2006-06-17
		
		NOTE: 
	
		-	MUST be used ONLY with MySQL 4.1+ as it requires subqueries
		-	$gv_sql must be defined appropriately
		-	-cattable will be required to be passed in all operations
		
		DESCRIPTION
			addSibling
				Adds an entry AFTER specified item, at the same depth
			addChild
				Adds a child to the specified item.
				Usually employed when there is no existing child.
			addRoot
				Adds a node at the root - at the end
			deleteNode
				Self-descriptive... DELETES the node and all it's child nodes.
			moveNode
				Self-descriptive... MOVES the node and all it's child nodes in the specified direction.
			moveNodeTo
				Moves given node + nested nodes to inside a given node's id.
			fullCatSQL
				Returns the SQL required to extract the full tree.
			subTreeSQL
				Returns the SQL required to extract the tree branching from a specified node.
			showPathSQL
				Returns the SQL that will extract the linear path from the root to the node.
			getParent
				Returns a map, id and parentname
			getURLpath
				Returns the url page like /hello/world/ from an id
		
		USAGE:
		xs_cat->(addSibling(-cattable='category',-txt='Hello World',-id=10));
		xs_cat->(addChild(-cattable='category',-txt='Hello World',-id=10));
		xs_cat->(deleteNode(-cattable='category',-id=10));
		xs_cat->(moveNode(-cattable='category',-id=10));
		xs_cat->(moveNodeTo(-cattable='category',-id=10,-newparent=23));
		xs_cat->(fullCatSQL(-cattable='category',-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'));
		xs_cat->(subTreeSQL(-cattable='category',-id=23,-depth=2,-relative=true,-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'));
		xs_cat->(showPathSQL(-cattable='category',-xtraReturn=',column1, column2',-xtraWhere='SQL statement here'));
	
		CHANGES:
		2006-06-17
			Added order to fullcatSQL
		2007-12-13 ECL
		Added the field "Active" to indicate whether node or items below it in heirarchy are active
	*/
	// -----------------------------------------------------------
if:!(Lasso_TagExists:'xs_cat');
	define_type('cat',
					-Priority='replace',
					-namespace='xs_',
					-prototype);

		define_tag('addSibling',
					-Required='cattable',
					-Required='txt',
					-Optional='othersmap',
					-Required='id');
			// ADDS ENTRY AFTER ANOTHER CHILD, SAME LEVEL
			local('xtraFields' = string);
			local('xtraValues' = string);
			if(local_defined('othersmap') && local('othersmap')->(IsA('Map')));
				iterate(#othersmap,local('temp'));
					#xtraFields += ','+#temp->name;
					(#temp->value == 'NOW()')? #xtraValues += ',NOW()' | #xtraValues += ',"'+#temp->value+'"';
				/iterate;
			/if;
			local('uniqueSeed' = lasso_uniqueid);
			local('sSQL' = '
				LOCK TABLE '+#cattable+' WRITE;
				
				SELECT @myRight := rgt FROM '+#cattable+' WHERE id = '+#id+';
				
				UPDATE '+#cattable+' SET rgt = rgt + 2 WHERE rgt > @myRight;
				UPDATE '+#cattable+' SET lft = lft + 2 WHERE lft > @myRight;
				
				INSERT INTO '+#cattable+'(name, lft, rgt'+#xtraFields+',uniqueSeed,Active) VALUES("'+(encode_sql(#txt))+'", @myRight + 1, @myRight + 2'+#xtraValues+',"'#uniqueSeed'","Y");
				
				UNLOCK TABLES;');
			inline($gv_sql,-SQL=#sSQL);
				xs_iserror;
				inline($gv_sql,-SQL='SELECT id FROM '#cattable' WHERE uniqueSeed = "'#uniqueSeed'" LIMIT 1');
					records;
						return(field('id'));
					/records;
				/inline;
			/inline;
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - addSibling';


		define_tag('addChild',
					-Required='cattable',
					-Required='txt',
					-Optional='othersmap',
					-Required='id');
			// ADDS ENTRY NESTED INSIDE CAT WHERE NO CHILD EXISTS
			local('xtraFields' = string);
			local('xtraValues' = string);
			if(local_defined('othersmap') && local('othersmap')->(IsA('Map')));
				iterate(#othersmap,local('temp'));
					#xtraFields += ','+#temp->name;
					(#temp->value == 'NOW()')? #xtraValues += ',NOW()' | #xtraValues += ',"'+#temp->value+'"';
				/iterate;
			/if;
			local('uniqueSeed' = lasso_uniqueid);
			local('sSQL' = '
				LOCK TABLE '+#cattable+' WRITE;
				
				SELECT @myLeft := lft FROM '+#cattable+' WHERE id = '+#id+';
				
				UPDATE '+#cattable+' SET rgt = rgt + 2 WHERE rgt > @myLeft;
				UPDATE '+#cattable+' SET lft = lft + 2 WHERE lft > @myLeft;
				
				INSERT INTO '+#cattable+'(name, lft, rgt'+#xtraFields+',uniqueSeed,Active) VALUES("'+(encode_sql(#txt))+'", @myLeft + 1, @myLeft + 2'+#xtraValues+',"'#uniqueSeed'","Y");
				
				UNLOCK TABLES;');
			
			inline($gv_sql,-SQL=#sSQL);
				xs_iserror;
				inline($gv_sql,-SQL='SELECT id FROM '#cattable' WHERE uniqueSeed = "'#uniqueSeed'" LIMIT 1');
					records;
						return(field('id'));
					/records;
				/inline;
			/inline;
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - addChild';

		define_tag('addRoot',
					-Required='cattable',
					-Required='txt',
					-Optional='othersmap');
			// ADDS ROOT NODE AT END
			local('xtraFields' = string);
			local('xtraValues' = string);
			if(local_defined('othersmap') && local('othersmap')->(IsA('Map')));
				iterate(#othersmap,local('temp'));
					#xtraFields += ','+#temp->name;
					(#temp->value == 'NOW()')? #xtraValues += ',NOW()' | #xtraValues += ',"'+#temp->value+'"';
				/iterate;
			/if;
			local('uniqueSeed' = lasso_uniqueid);
			local('sSQL' = '
				LOCK TABLE '+#cattable+' WRITE;
				
				SELECT @myRight := rgt FROM '+#cattable+' ORDER BY rgt DESC LIMIT 1;
				
				INSERT INTO '+#cattable+'(name, lft, rgt'+#xtraFields+',uniqueSeed,Active) VALUES("'+(encode_sql(#txt))+'", @myRight + 1, @myRight + 2'+#xtraValues+',"'#uniqueSeed'","Y");
				
				UNLOCK TABLES;');
			
			inline($gv_sql,-SQL=#sSQL);
				xs_iserror;
				inline($gv_sql,-SQL='SELECT id FROM '#cattable' WHERE uniqueSeed = "'#uniqueSeed'" LIMIT 1');
					records;
						return(field('id'));
					/records;
				/inline;
			/inline;
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - addRoot';

		define_tag('deleteNode',
					-Required='cattable',
					-Required='id');
			// DELETE A NODE
			local('sSQL' = '
				LOCK TABLE '+#cattable+' WRITE;
	
				SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1
				FROM '+#cattable+'
				WHERE id = '+#id+';
				
				DELETE FROM '+#cattable+' WHERE lft BETWEEN @myLeft AND @myRight;
				
				UPDATE '+#cattable+' SET rgt = rgt - @myWidth WHERE rgt > @myRight;
				UPDATE '+#cattable+' SET lft = lft - @myWidth WHERE lft > @myRight;
				
				UNLOCK TABLES;');
		//	$gv_feedback += #sSQL;
			inline($gv_sql,-SQL=#sSQL);
				xs_iserror;
			/inline;
			
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - deleteNode';


		define_tag('moveNode',
					-Required='cattable',
					-Required='id');
		/*
1		Calculate the branch width of the branch you want to move.
2		Update all lft and rgt values on the branch you want to move by multiplying them by -1.
3		Update all values on the tree as though the branch you just negated was deleted.
4		Update all lft values that are greater than the rgt value of the node you want to move the branch to by adding the branch width + 2 to them.
5		Update all rgt values that are greater than or equal to the rgt value of the node you want to move the branch to by adding the branch width + 2 to them.
6		Find the greatest negative lft value in the table, 
			which will be the top of the branch that you are moving, multiply it by -1 and call it x.
7		Find the lft value of the node that you want to attach the branch to, and call it y.
8		Calculate (y - x + 1) = z . Update all negative values in the table by subtracting z from them.
9		Update all negative values in the tree by multiplying them by -1.
		*/
		local('id2' = 0);
		// get immediate prior sibling
				local('sSQL' = (
				'
			SELECT node.id, node.name, (COUNT(parent.id) - (sub_tree.depth + 1)) AS depth, node.lft, node.rgt
			FROM '+#cattable+' AS node,
		        '+#cattable+' AS parent,
		        '+#cattable+' AS sub_parent,
		        (
		                SELECT node.name, (COUNT(parent.id) - 1) AS depth
		                FROM '+#cattable+' AS node,
		                '+#cattable+' AS parent
		                WHERE node.lft BETWEEN parent.lft AND parent.rgt
		                AND node.id = 
		                		(
							SELECT parent.id
							FROM '+#cattable+' AS node,
							'+#cattable+' AS parent
							WHERE node.lft BETWEEN parent.lft AND parent.rgt
							AND node.id = '+#id+' AND parent.id != '+#id+'
							ORDER BY parent.lft DESC LIMIT 1
							)
		                GROUP BY node.name
		                ORDER BY node.lft
		        )AS sub_tree
			WHERE node.lft BETWEEN parent.lft AND parent.rgt
		        AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
		        AND sub_parent.name = sub_tree.name
			GROUP BY node.id
			HAVING depth = 1
			ORDER BY node.lft ASC;'
				));
				inline($gv_sql,-SQL=#sSQL);
					records;
						if(integer(field('id')) != #id);
							#id2 = integer(field('id'));
						else;
							loop_abort;
						/if;
					/records;
				/inline;
				
				if(#id2 == 0);
					// here we are trying to ascertain if it's a root node!
					#sSQL = '
						SELECT node.id, node.name, (COUNT(parent.id) - 1) AS depth
						FROM '+#cattable+' AS node,
						'+#cattable+' AS parent
						WHERE node.lft BETWEEN parent.lft AND parent.rgt
						AND node.id = '+#id+'
						GROUP BY node.id
						ORDER BY node.lft';
					inline($gv_sql,-SQL=#sSQL);
						records;
							if(integer(field('depth')) == 0);
								// yay, it's a root node!!!
								#sSQL = '
									SELECT node.id, node.name, (COUNT(parent.id) - 1) AS depth
									FROM '+#cattable+' AS node,
									'+#cattable+' AS parent
									WHERE node.lft BETWEEN parent.lft AND parent.rgt
									GROUP BY node.id
									HAVING depth = 0
									ORDER BY node.lft';
								inline($gv_sql,-SQL=#sSQL);
									records;
										if(integer(field('id')) != #id);
											#id2 = integer(field('id'));
										else;
											loop_abort;
										/if;
									/records;
								/inline;
							/if;
						/records;
					/inline;
				/if;
				
				if(#id2 > 0);
				#sSQL = ('
					LOCK TABLE '+#cattable+' WRITE;
		-- 1			
					SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#id2+';
		-- 2					
					UPDATE '+#cattable+' SET rgt = (rgt*-1), lft = (lft*-1) WHERE lft BETWEEN @myLeft AND @myRight;
		-- 3		
					UPDATE '+#cattable+' SET rgt = rgt - @myWidth WHERE rgt > @myRight;
					UPDATE '+#cattable+' SET lft = lft - @myWidth WHERE lft > @myRight;
		-- 4a
					SELECT @myLeft2 := lft, @myRight2 := rgt, @myWidth2 := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#id+';
		-- 4 & 5			
					UPDATE '+#cattable+' SET rgt = rgt + @myWidth WHERE rgt > @myRight2;
					UPDATE '+#cattable+' SET lft = lft + @myWidth WHERE lft > @myRight2;
		-- 6
		--			SELECT @x := (@myRight2 + 1) - (lft * -1) FROM '+#cattable+' WHERE id = '+#id+';
					SELECT @x := lft FROM '+#cattable+' WHERE id = '+#id+';
					SELECT @y := rgt FROM '+#cattable+' WHERE id = '+#id+';
		-- 8
					UPDATE '+#cattable+' SET rgt = (rgt - (@y - @x + 1)) WHERE rgt < 0;
					UPDATE '+#cattable+' SET lft = (lft - (@y - @x + 1)) WHERE lft < 0;
		
					UPDATE '+#cattable+' SET rgt = rgt * -1 WHERE rgt < 0;
					UPDATE '+#cattable+' SET lft = lft * -1 WHERE lft < 0;
		
					UNLOCK TABLES;');
				inline($gv_sql,-SQL=#sSQL);
				/inline;
			/if;
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - moveNode';

		define_tag('moveNodeTo',
					-Required='cattable',
					-Required='id',
					-Required='newparent');
		local('sSQL' = string);

			if(#newparent > 0 && #id > 0);
				#sSQL = ('
					LOCK TABLE '+#cattable+' WRITE;
		-- 1	, get boundaries of chunk to move
					SELECT @myLeft := lft, @myRight := rgt, @myWidth := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#id+';
		
		-- 2	, make chunk negative (ie move outta da way)		
					UPDATE '+#cattable+' SET rgt = ((rgt-@myRight)-1), lft = ((lft-@myRight)-1) WHERE lft BETWEEN @myLeft AND @myRight;
		
		-- 3	, collapse
					UPDATE '+#cattable+' SET rgt = rgt - @myWidth WHERE rgt > @myRight;
					UPDATE '+#cattable+' SET lft = lft - @myWidth WHERE lft > @myRight;

		-- 4, get boundaries of new parent
					SELECT @myRight2a := rgt FROM '+#cattable+' WHERE id = '+#newparent+';
										
		-- 5	, expand new parent + others to hold content
					UPDATE '+#cattable+' SET rgt = rgt + @myWidth WHERE rgt >= @myRight2a; -- note >= is new addition
					UPDATE '+#cattable+' SET lft = lft + @myWidth WHERE lft > @myRight2a;

		-- 6, get boundaries of new parent
					SELECT @myLeft2 := lft, @myRight2 := rgt, @myWidth2 := rgt - lft + 1 FROM '+#cattable+' WHERE id = '+#newparent+';

		
		-- 8, take all less than 0 and ad myRight2, puts it automagically in teh right pos
					UPDATE '+#cattable+' SET rgt = (rgt + @myRight2) WHERE rgt < 0;
					UPDATE '+#cattable+' SET lft = (lft + @myRight2) WHERE lft < 0;
					
					UNLOCK TABLES;');
				inline($gv_sql,-SQL=#sSQL);
					xs_iserror;
				/inline;
			/if;
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - moveNodeTo';


		define_tag('fullCatSQL',
					-Required='cattable',
					-Optional='xtraReturn',
					-Optional='xtraWhere',
					-Optional='orderby',
					-Optional='depth');
			(!(local_defined('xtraReturn'))) ? local('xtraReturn' = string);
			(!(local_defined('xtraWhere'))) ? local('xtraWhere' = string);
			if(!(local_defined('depth')));
				local('depthComp' = string);
			else(string(#depth) != '');
				local('depthComp' = 'HAVING depth <= '+#depth);
			else;
				local('depthComp' = string);
			/if;
			if(!(local_defined('orderby')));
				local('orderComp' = 'node.lft');
			else;
				local('orderComp' = #orderby);
			/if;
			/*
				Returns full category list incl depth.
				To specify additional columns returned use xtraReturn parameter
				To specify additional restrictions in WHERE clause, use xtraWhere parameter
				
				An example of xtraReturn is as follows:
',
	(
		SELECT COUNT(*)
	        FROM asset, category AS subc
	        WHERE asset.category_id = subc.id
	        AND subc.lft BETWEEN node.lft AND node.rgt
	)AS chqty,
	(
	SELECT COUNT(asset.name) FROM asset WHERE asset.category_id = node.id
	)AS qty,
	(
        SELECT COUNT(*) - 1
        FROM category AS nnode
        WHERE nnode.lft BETWEEN node.lft AND node.rgt
    )AS nchild'				
			*/
			return('/* fullCatSQL */
SELECT 
	node.id, node.name, (COUNT(parent.id) - 1) AS depth '+#xtraReturn+'
FROM '+#cattable+' AS node,
'+#cattable+' AS parent
WHERE node.lft BETWEEN parent.lft AND parent.rgt '+#xtraWhere+'
GROUP BY node.id
'+#depthComp+'
ORDER BY '+#orderComp);		

		/define_tag;
		Log_Critical: 'Custom Tag Loaded - fullCatSQL';


		define_tag('subTreeSQL',
					-Required='cattable',
					-Required='id',
					-Optional='depth',
					-Optional='relative',
					-Optional='xtraReturn',
					-Optional='xtraWhere',
					-Optional='usage');
			(!(local_defined('usage'))) ? local('usage' = string);
			(!(local_defined('xtraReturn'))) ? local('xtraReturn' = string);
			(!(local_defined('xtraWhere'))) ? local('xtraWhere' = string);
			(!(local_defined('relative')) || (local('relative') == false)) ? local('relative' = '1') | local('relative' = '(sub_tree.depth + 1)');
			if(!(local_defined('depth')));
				local('depthComp' = string);
			else(integer(#depth) > 0);
				local('depthComp' = 'HAVING depth <= '+#depth);
			else;
				local('depthComp' = string);
			/if;

			//(sub_tree.depth + 1) - makes the depth relative to the one requested
			//HAVING depth <= 1 - limits how many subs it pulls in

/*
================================================================================
From Pier 23/05/2006 16:26

Added node.id to the nested SELECT so that we can replace
	[...] sub_parent.name = sub_tree.name [...]
with 
	[...] sub_parent.id = sub_tree.id [...]
================================================================================
*/
			local('out' = '/* subTreeSQL */
			SELECT node.id');
			#usage != 'in' ? #out += ', node.name, (COUNT(parent.id) - '+#relative+') AS depth '+#xtraReturn;
			
			#out += '	FROM '+#cattable+' AS node,
				        '+#cattable+' AS parent,
				        '+#cattable+' AS sub_parent,
				        (
				                SELECT node.id, node.name, (COUNT(parent.id) - 1) AS depth
				                FROM '+#cattable+' AS node,
				                '+#cattable+' AS parent
				                WHERE node.lft BETWEEN parent.lft AND parent.rgt
				                AND node.id = '+#id+'
				                GROUP BY node.name
				                ORDER BY node.lft
				        )AS sub_tree
				WHERE node.lft BETWEEN parent.lft AND parent.rgt
				        AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
				        AND sub_parent.id = sub_tree.id '+#xtraWhere+'
				GROUP BY node.id
				'+#depthComp;
// Changing sort order to order by name
//			#usage != 'in' ? #out += ' ORDER BY node.lft;';
			#usage != 'in' ? #out += ' ORDER BY node.name;';

			// Debugging, uncomment to get log entry of query
			// Log_Critical: 'subTreeSQL: #out = ' (#out);

			return(#out);
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - subTreeSQL';


		define_tag('showPathSQL',
					-Required='cattable',
					-Required='id',
					-Optional='xtraReturn',
					-Optional='xtraWhere');
			(!(local_defined('xtraReturn'))) ? local('xtraReturn' = string);
			(!(local_defined('xtraWhere'))) ? local('xtraWhere' = string);

			local('out' = '/* showPathSQL */
			SELECT node.id, node.name, (COUNT(parent.id) - 1) AS depth '+#xtraReturn+'
	FROM '+#cattable+' AS node,
	        '+#cattable+' AS parent,
	        (
	        	SELECT sub.lft AS sublft, sub.rgt AS subrgt
	        	FROM '+#cattable+' AS sub
	        	WHERE sub.id = '+#id+'
	        ) AS sub
	WHERE 
			node.lft <= sub.sublft
        AND 	node.rgt >= sub.subrgt
		AND node.lft BETWEEN parent.lft AND parent.rgt '+#xtraWhere+'
	GROUP BY node.id
	ORDER BY node.lft
				;');
				return(#out);
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - showPathSQL';
		
		define_tag('getParent',
					-Required='cattable',
					-Required='id',
					-Optional='xtraWhere');		
//					-Optional='xtraReturn',

			(!(local_defined('xtraReturn'))) ? local('xtraReturn' = string);
			(!(local_defined('xtraWhere'))) ? local('xtraWhere' = string);

			local('out' = map);
			local('sSQL' = '/* getParent */
				SELECT 
					parent.id,parent.name '+#xtraReturn+'
				FROM 
					'+#cattable+' AS node,
					'+#cattable+' AS parent
				WHERE 
					node.lft BETWEEN parent.lft AND parent.rgt
					AND node.id = '+#id+'
					AND parent.id != node.id
					'+#xtraWhere+'
				ORDER BY 
					parent.lft DESC
				LIMIT 1');			
			inline($gv_sql,-SQL=#sSQL);
				records;
					#out->insert('id'=field('id'),'parentname'=field('name'));
				/records;
			/inline;
			return(#out);
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - getParent';

// 6/12/09 ECL
// New tag to get home node
		define_tag('getHome',
					-Required='cattable');

			local('out' = map);
			local('sSQL' = '/* getHome */
				SELECT id, name FROM '+#cattable+' WHERE node.name = "Home" LIMIT 1');
			inline($gv_sql,-SQL=#sSQL);
				records;
					#out->insert('id'=field('id'),'parentname'=field('name'));
				/records;
			/inline;
			return(#out);
		/define_tag;
		Log_Critical: 'Custom Tag Loaded - getHome';

		// 11/21/07 ECL
		// NOTE: This fetches needs a field named page_url in the cattable
		// Currently we do not use this
		define_tag('getURLpath',
					-Required='cattable',
					-Required='id',
					-Description='Returns the url page like /hello/world/ from an id');		

			local('out' = '/');
			local('sSQL' = '
			/* getURLpath */
				SELECT node.id, node.page_url, (COUNT(parent.id) - 1) AS depth 
				FROM '+#cattable+' AS node,
				       '+#cattable+'  AS parent,
				        (
				        	SELECT sub.lft AS sublft, sub.rgt AS subrgt
				        	FROM '+#cattable+' AS sub
				        	WHERE sub.id = '+#id+'
				        ) AS sub
				WHERE 
						node.lft <= sub.sublft
			        AND 	node.rgt >= sub.subrgt
					AND node.lft BETWEEN parent.lft AND parent.rgt 
				GROUP BY node.id
				ORDER BY node.lft');			
			inline($gv_sql,-SQL=#sSQL);
				records;
					#out += field('page_url') + '/';
				/records;
			/inline;
			return(#out);
		/define_tag;		
		Log_Critical: 'Custom Tag Loaded - getURLPath';

	/define_type;
/if;

?>