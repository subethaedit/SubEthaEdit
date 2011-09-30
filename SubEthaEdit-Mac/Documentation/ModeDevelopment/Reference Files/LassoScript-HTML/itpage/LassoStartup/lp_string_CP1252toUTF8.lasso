[

define_tag:'lp_string_CP1252toUTF8',
	-description='Converts CP1252 (aka Windows-1252) characters to their UTF-8 equivalents.',
	-priority='replace',
	-required='string';

	/*
	http://www.microsoft.com/globaldev/reference/sbcs/1252.mspx
	http://www.cs.tut.fi/~jkorpela/www/windows-chars.html
	http://www.geocities.com/stmetanat/smartquotes.htm
	http://catb.org/~esr/jargon/html/D/dread-questionMark-disease.html
	http://www.fourmilab.ch/webtools/demoroniser/
	*/

	/*
	Conversion chart to UCS - http://www.microsoft.com/globaldev/reference/sbcs/1252.mspx���������������������������
	
	128	80 = U+20AC : EURO SIGN
	129	81 = 
	130	82 = U+201A : SINGLE LOW-9 QUOTATION Mark
	131	83 = U+0192 : LATIN SMALL LETTER F WITH HOOK
	132	84 = U+201E : DOUBLE LOW-9 QUOTATION Mark
	133	85 = U+2026 : HORIZONTAL ELLIPSIS
	134	86 = U+2020 : DAGGER
	135	87 = U+2021 : DOUBLE DAGGER
	136	88 = U+02C6 : MODIFIER LETTER CIRCUMFLEX ACCENT
	137	89 = U+2030 : PER MILLE SIGN
	138	8A = U+0160 : LATIN CAPITAL LETTER S WITH CARON
	139	8B = U+2039 : SINGLE LEFT-POINTING ANGLE QUOTATION Mark
	140	8C = U+0152 : LATIN CAPITAL LIGATURE OE
	141	8D = 
	142	8E = U+017D : LATIN CAPITAL LETTER Z WITH CARON
	143	8F =
	144	90 =
	145	91 = U+2018 : LEFT SINGLE QUOTATION Mark
	146	92 = U+2019 : RIGHT SINGLE QUOTATION Mark
	147	93 = U+201C : LEFT DOUBLE QUOTATION Mark
	148	94 = U+201D : RIGHT DOUBLE QUOTATION Mark
	149	95 = U+2022 : BULLET
	150	96 = U+2013 : EN DASH
	151	97 = U+2014 : EM DASH
	152	98 = U+02DC : SMALL TILDE
	153	99 = U+2122 : TRADE Mark SIGN
	154	9A = U+0161 : LATIN SMALL LETTER S WITH CARON
	155	9B = U+203A : SINGLE RIGHT-POINTING ANGLE QUOTATION Mark
	156	9C = U+0153 : LATIN SMALL LIGATURE OE
	157	9D = 
	158	9E = U+017E : LATIN SMALL LETTER Z WITH CARON
	159	9F = U+0178 : LATIN CAPITAL LETTER Y WITH DIAERESIS

	*/
	
	local:'cp1252_to_utf8' =
		(map:
			128 = 14844588,
			129 = 129,
			130 = 14844058,
			131 = 50834,
			132 = 14844062,
			133 = 14844070,
			134 = 14844064,
			135 = 14844065,
			136 = 52102,
			137 = 14844080,
			138 = 50592,
			139 = 14844089,
			140 = 50578,
			141 = 141,
			142 = 50621,
			143 = 143,
			144 = 144,
			145 = 14844056,
			146 = 14844057,
			147 = 14844060,
			148 = 14844061,
			149 = 14844066,
			150 = 14844051,
			151 = 14844052,
			152 = 52124,
			153 = 14845090,
			154 = 50593,
			155 = 14844090,
			156 = 50579,
			157 = 157,
			158 = 50622,
			159 = 50616
		);


	if: #string->type != 'bytes';

		local:'return' = string;
		iterate: (string: #string), local:'s';
			if: (lp_logical_between: #s->integer, 128, 159);
				#return += lp_string_chr: (#cp1252_to_utf8->(find: #s->integer));
			else;
				#return += #s;
			/if;
		/iterate;
	
		return: #return;

	else; // bytes
	
		local:'return' = bytes;
		iterate: #string, local:'s';
			if: (lp_logical_between: #s, 128, 159);
				iterate: lp_math_decToOctet: #cp1252_to_utf8->(find: #s), local:'octet';
					#return->(import8bits: #octet);
				/iterate;
			else;
				#return->(import8bits: #s);
			/if;
		/iterate;
	
		return: #return;

	/if;

/define_tag;

]