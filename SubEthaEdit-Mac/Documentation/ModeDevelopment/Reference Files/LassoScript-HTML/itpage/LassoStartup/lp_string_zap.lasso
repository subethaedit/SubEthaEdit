[

define_tag:'lp_string_zap',
	-description='Returns a string with all non-plain-ascii characters removed.',
	-priority='replace',
	-required='text_to_zap',
	-optional='replacement_text';

	if: !(local_defined:'replacement_text');
		local:'replacement_text' = '';
	/if;

	return: (string_replaceregexp: #text_to_zap, -find='[^\\x20-\\x7E\\x09\\x0A\\x0D]', -replace=#replacement_text);
/define_tag;

/* Example

[var:'teststring' = 'test test 123\t123' + (decode_url:'%80') + (decode_url:'%81')]
<pre>
Test String: (<b>[$teststring]</b>)<br>
Zap (remove bad chars): (<b>[lp_string_zap: $teststring]</b>)<br>
Zap (replace bad chars with *): (<b>[lp_string_zap: $teststring, '*']</b>)<br>
</pre>

*/

]
