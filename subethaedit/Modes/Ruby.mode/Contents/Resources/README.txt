Improved Ruby Mode
(The Improved Ruby syntax hilighter for SubEthaEdit 2.0)
(c) Jeff Reinecke, 2004 - jeff@paploo.net
(c) The Coding Monkeys, 2004

This code is based on the original Ruby Mode distributed with
SubEthaEdit 2.0a.

==================== OVERVIEW ====================

This is a syntax hilighting mode for Ruby under SubEthaEdit 2.0.  It is
greatly improved over the default version, including better function pop-up
recognition and naming, hilighting of builtin functions and globals,
highlighting of user class variables, instance variables, and globals,
support for eruby and mod_ruby documents, and much more.  For a full list, 
see the change history.

==================== QUICK START ====================

You may drop this file into one of the following directories:

+ ~/Library/Application Support/SubEthaEdit/Modes/
+ /Library/Application Support/SubEthaEdit/Modes/
+ /Network/Library/Application Support/SubEthaEdit/Modes/

As of this release, you must quit and restart SubEthaEdit to get the
mode to load.  You will see this mode as "Ruby-Improved" in the Mode menu,
and it will take over the handling of Ruby related files automatically.

==================== DISCLAIMER/LISCENSE ====================

Use this softare at your own discretion.  Neither myself (Jeff Reinecke),
nor the authors of SubEthaEdit, as well as the distributors of the
Improved Ruby Mode or SubEthaEdit can be held responsible for any damages
that this software may cause.  Of course, I seriously doubt anything will
go wrong, but I need to cover my arse, leagally speaking.  :)

This syntax coloring mode may be freely distributed and/or modified as
you wish, providing that (1) credit be given to both myself (Jeff Reinecke)
and to the authors of SubEthaEdit for our contribustions, and (2) that
since this is a derivative work of the authors of SubEthaEdit, they still
retain copyright for the protions they wrote, and thus have the right
to stop distribution of this syntax coloring mode and any derivative work
that still contains portions of the original Ruby syntax coloring mode
that this is based upon.

==================== CONTACT ====================

If you have any questions, comments, feature requests, et cetera, 
I very much like to get e-mail, and will be more than happy to answer
your questions.  Please e-mail me at jeff@paploo.net.  If you have a
bug report, please see my known bugs list.

========== CHANGE HISTORY / KNOWN BUGS / PLANNED FEATURES ==========

---------- 2.1.1 (15-June-2004) ----------

+ [fix] eruby documents now support the '<%# blah %>' one line comment style.
Indeed, ending an erbuy block with a comment on the same line now always works.

+ [fix] The $' and $` globals now color right, instead of starting a single
quoted string and a shell execution string coloring mode.

---------- 2.1 (14-June-2004) ----------

+ [fix] Regexp coloring doesn't crash SubEthaEdit anymore!  Yay!  Actaully,
I mangaged to get regexps to come out right in every situation I tried, which means
I'm missing something obvious/important.  Someone should try to find something
that breaks it for me.

+ [addition] Added POD comment support.  Now files such as cgi.rb look right
when you open them.

+ [fix] Comments on class definition lines no longer show-up in the function
pop-up list

+ [fix] A standalone '-', '+', and '.' are not colored as numbers.

+ [fix] Better recognition of only valid number literals.  (e.g., literals like 4.E5,
which aren't valid syntax, are no longer hilighted.  I *think* only valid numbers are
hilighted now... but we'll see.

+ [fix] More accurate recognition numbers from characters literals (like ?a and ?\n)

+ [fix] The '<%=' eruby tag is now fully colored.  You can't start tags names with
an equals sign anymore, but that isn't proper XML anyway.  (Of course, neither is
eruby's use of '<%' instead of '<?eruby'!)


---------- 2.0 (11-June-2004) ----------

+ [addition] Added support for html markup for .rhtml files (eruby files).
I stole stuff from the PHP-HTML mode that came with SubEthaEdit to
get this working in a hurry.

+ [addition] Added support for mod_ruby CGI scripts with the .rbx syntax.  This
was really just a matter of adding the .rbx file extension to the list.

+ [removal] The POD comment support wasn't working right, and actually
interfered with some of the eruby related hilighting, so I am holding
off on that for now.
 

---------- 1.0 (Not publicly released) ----------

+ [fix] Recognizes '@' and '$' as being valid characters in variable
names now.

+ [addition] Added syntax coloring of all the builtin functions.

+ [addition] Added syntax coloring for all the buildin global variables.

+ [fix] More extensive and robust number hilighting.  Supports full Ruby
number literal spec.

+ [addition] Added syntax coloring of instance variables, class variables,
and user defined global variables.

+ [addition] Added syntax hilighting of interpolation sections of Ruby
strings.  (e.g., the #{foo} portion of the string "The tree is #{foo}.")

+ [addition] Regexp coloration.  This isn't very robust so don't be
surprised if it doesn't work in all conditions.

+ [fix] Recognizes all legal Ruby function names.  The default hilighter
couldn't recognize many legal ones and would just leave them out of the
function list.  It currently displays the function names the way I like
to see them.


---------- Known Bugs ----------

+ Starting a block of ruby code inside of an eruby file before the first <html>
tag makes the '<%' not color right.  This is because the html state wasn't entered
and thus the coloring for the eruby tag doesn't know to color itself.

+ A comment line containing '%>' will not color as a comment starting after that.
This is an unavoidable consequence of building eruby support into this coloring
mode.  Fortunately, comments containing this text are rare.

+ builtin functions and globals are syntax colored even if they syntactically shouldn't
be.  Try these out to see what I meand, keeping in mind that 'puts' is a builtin
function and 'ARGF' is a builtin global, but that 'puts' is also being used as a
variable here and 'ARGF' is being used as a function:
	puts = "This is a string"
	puts puts  #This prints the value of puts to stdout
	class Foo
		def ARGF
			puts "ARGF called"
		end
	end
	f = Foo.new
	f.ARGF
I, of course, would NOT recommend this code as good programming practice.  :)


---------- Planned Features ----------

+ Inclusion of the ioxm options, which can be after a regexp, in the
regexp syntax coloring. (eg /foo/im should all be colored.)  Not sure how
I'm going to accomplish this yet.
