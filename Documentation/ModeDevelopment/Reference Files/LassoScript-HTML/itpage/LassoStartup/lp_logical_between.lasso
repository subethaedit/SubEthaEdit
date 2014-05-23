[

define_tag:'lp_logical_between',
	-description='Evaluates if a value is inclusively between a high and low value.  Returns true or false.',
	-priority='replace',
	-required='value',
	-required='low',
	-required='high';
	
	select: #value->type;
		case:'integer';
			return: (integer:#value) >= (integer:#low) && (integer:#value) <= (integer:#high);
		case:'decimal';
			return: (decimal:#value) >= (decimal:#low) && (decimal:#value) <= (decimal:#high);
		case:'string';
			return: (string:#value) >= (string:#low) && (string:#value) <= (string:#high);
		case;
			fail: -1, 'Value must be of type integer, decimal, or string.';
	/select;

	/*
	lp_logical_between: 5, 2, 6;
	'<br>';
	lp_logical_between: 5, 2, 4;
	'<br>';
	lp_logical_between: 5.2, 5.199999, 5.20001;
	'<br>';
	lp_logical_between: 'e', 'a', 'f';
	'<br>';
	lp_logical_between: 'e', 'a', 'd';
	*/


/define_tag;

]