[

/*
define_tag:'x',-required='string';
	local:'return' = array;
	iterate:#string->(split:','), local:'s';
		#return->(insert: (lp_math_hextodec: #s));
	/iterate;
	return: #return->(join:', ');
/define_tag;
*/

// Usage
/*
lp_string_extendedtoplain:'abcd ABCD räksmörgås / RÄKSMÖRGÅS / € ‚ ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • – — ˜ ™ š › œ ž Ÿ ¿ ¡';
'<br>\n';
lp_string_extendedtoplain:'abcd ABCD räksmörgås / RÄKSMÖRGÅS / € ‚ ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • – — ˜ ™ š › œ ž Ÿ ¿ ¡',-nozap;
*/

// Depenedencies
// lp_string_CP1252toUTF8.lasso
// lp_logical_in.lasso
// lp_logical_between.lasso
// lp_string_zap.lasso

define_tag:'lp_string_extendedToPlain',
	-description='Converts extended characters in UTF-8 to their plain ASCII equivalents.',
	-priority='replace',
	-required='string',-copy;

	local:'return' = string;
	local:'letter' = string;

	local:'zap' = true;
	if: params->(find:'-nozap')->size;
		#zap = false;
	/if;

	// first, make sure to convert screwy MS Word chars to standard UTF-8 (like "smart" quotes)
	#string = lp_string_CP1252toUTF8: (string: #string);

	// process one letter at a time
	iterate: #string, local:'s';
	
		// is it plain ascii already?
		if: #s->integer <= 127;
			#return += #s;
			loop_continue;
		/if;

		// convert foreign letters to plain letters
		if: (lp_logical_in: #s->chartype, (array: 'LOWERCASE_LETTER','UPPERCASE_LETTER'));
			#letter = (string_findregexp: #s->charname, -find='\\b[A-Z]\\b', -ignorecase);
			if: #letter->size;
				if: #s->chartype == 'LOWERCASE_LETTER';
					#return += string_lowercase: (#letter->(get:1));
				else: #s->chartype == 'UPPERCASE_LETTER';
					#return += string_uppercase: (#letter->(get:1));
				/if;
				loop_continue;
			/if;
		/if;


		// convert foreign punctuation to plain punctuation
		if: (lp_logical_in: #s->integer, (: 160, 12288));  // 00A0, 3000
 			#return += ' ';
			loop_continue;
		else: (lp_logical_in: #s->integer, (: 451, 10082));  // 01C3, 2762
			#return += '!';
			loop_continue;
 		else: (lp_logical_in: #s->integer, (: 8252));  // 203C
 			#return += '!!';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8253, 8264));  // 203D, 2048
 			#return += '?!';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8265));  // 2049
 			#return += '!?';
			loop_continue;
   		else: (lp_logical_in: #s->integer, (: 698, 8243, 12291, 8220, 8221, 8222, 8223, 8246));  // 02BA, 2033, 3003, 201C, 201D, 201E, 201F, 2036
 			#return += '"';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 9839));  // 266F
 			#return += '#';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 1642));  // 066A
 			#return += '%';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8216, 8217, 697, 700, 712, 8242, 8245, 8218, 8219));  // 2018, 2019, 02B9, 02BC, 02C8, 2032, 2035, 201A, 201B
 			#return += "'";
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 1645, 8270, 8727, 10033, 183, 903, 8226, 8227, 8228, 8231, 8729, 8901, 12539, 9688, 9702, 8718, 9656));  // 066D, 204E, 2217, 2731, 00B7, 0387, 2022, 2023, 2024, 2027, 2219, 22C5, 30FB, 25D8, 25E6, 220E, 25B8
 			#return += '*';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 1548, 12289));  // 060C, 3001
 			#return += ',';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8208, 8209, 8722));  // 2010, 2011, 2212
 			#return += '-';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8210, 8211));  // 2012, 2013
 			#return += '--';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8212, 8213));  // 2014, 2015
 			#return += '---';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 212, 12290));  // 00D4, 3002
 			#return += '.';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8229));  // 2025
 			#return += '..';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8230));  // 2026
 			#return += '...';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8260, 8725, 247));  // 2044, 2215, 00F7
 			#return += '/';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8758));  // 2236
 			#return += ':';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 1563, 8271));  // 061B, 204F
 			#return += ';';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 9001, 10216, 12296));  // 2329, 27E8, 3008
 			#return += '<';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 9002, 10217, 12297));  // 232A, 27E9, 3009
 			#return += '>';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8800 ));  // 2260
 			#return += '<>';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 894, 1567));  // 037E, 061F
 			#return += '?';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8726));  // 2216
 			#return += '\\';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 708, 710, 8963));  // 02C4, 02C6, 2303
 			#return += '^';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 717, 8215));  // 02CD, 2017
 			#return += '_';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 715, 8245));  // 02CB, 2035
 			#return += '`';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 448, 8739, 10072));  // 01C0, 2223, 2758
 			#return += '|';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 732, 8275, 8764, 65374));  // 02DC, 2053, 223C, FF5E
 			#return += '~';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 169));  // 00A9
 			#return += '(c)';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 174));  // 00AE
 			#return += '(R)';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 177));  // 00B1
 			#return += '+/-';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 185));  // 00B9
 			#return += '1';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 178));  // 00B2
 			#return += '2';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 179));  // 00B3
 			#return += '3';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 188));  // 00BC
 			#return += '1/4';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8531));  // 2153
 			#return += '1/3';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8532));  // 2154
 			#return += '2/3';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8539));  // 215B
 			#return += '1/8';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8540));  // 215C
 			#return += '3/8';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8541));  // 215D
 			#return += '5/8';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8542));  // 215E
 			#return += '7/8';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 189));  // 00BD
 			#return += '1/2';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 190));  // 00BE
 			#return += '3/4';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 215));  // 00D7
 			#return += 'x';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8482));  // 2122
 			#return += 'TM';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8470));  // 2116
 			#return += 'No.';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8804));  // 2264
 			#return += '<=';
			loop_continue;
  		else: (lp_logical_in: #s->integer, (: 8805));  // 2265
 			#return += '>=';
			loop_continue;
		/if;
		
		//return: (x: '2025, 2026');
		
		// not a char we can convert
		#return += #s;
	/iterate;
	
	if: #zap;
		#return = (lp_string_zap: #return);
	/if;
	
	// return modified string
	return: #return;
	
/define_tag;


]