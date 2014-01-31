#make file for style sheet creation and style extraction and scope renaming
### Params
## xsltproc
## languages
## mode_directory
## result_mode_directory
## mode_syntax_def_suffix
## syntax_definition
## style_directory
## style_files
## syntax_files
## result_files
## result_mode_mode_directory
###
## from
## to
## scope
## mode
###

xsltproc=/usr/bin/xsltproc

# languages for which to generate a .sss-file : additional languages have to be added by hand
languages=ActionScript AppleScript ASP-HTML Base bash C C++ CFML Conference CSS Diff ERB erlang go HTML Java Javascript JSP-HTML LassoScript-HTML LaTeX Lua Objective-C Objective-J Pascal Perl PHP-HTML Python Ruby SDEF SQL SVNLog Wiki XML LESS Sass Smarty YAML

################################################################ Paths

## Path from which to look for mode files
#debug mode path
mode_directory=../../Modes/
#mode_directory=Coda2Modes/
#mode_directory=ResultModes/
#mode_directory=/Users/Lisa/Desktop/Modes/

## Directory to store the resulting modes at
result_mode_directory=ResultModes/
#result_mode_directory=/Users/Lisa/Desktop/Modes/

## Path that leads to the SyntaxDefinition of a mode
mode_syntax_def_suffix=.mode/Contents/Resources/SyntaxDefinition.xml

## File name SyntaxDefinition
syntax_definition="SyntaxDefinition.xml"

## Paths to the Style Sheet location
style_directory=ModeStyles/

##
style_files=$(addprefix $(style_directory), $(addsuffix .sss, $(languages)))
syntax_files=$(addprefix $(mode_directory), $(addsuffix $(mode_syntax_def_suffix), $(languages)))
result_files=$(addprefix $(result_mode_directory), $(addsuffix $(mode_syntax_def_suffix), $(languages)))
result_mode_mode_directory=$(addprefix $(result_mode_directory), $(addsuffix ".mode", $(languages)))

## Outside Parameter
from=meta.default
to=meta.default
scope=language.subroutine
mode=PHP-HTML

################################################################ Startup

all: how-to

how-to:
	@ echo " HOW-TO - call with the options you want, this is an umbrella makefile for rename, remove-styles, create-style-sheet";

################################################################ Real Recipes

rename:
	@ make -f make_rename.makefile from=$(from) to=$(to) syntax_files="$(syntax_files)" \
	xsltproc=$(xsltproc) mode_directory=$(mode_directory) result_mode_directory=$(result_mode_directory) mode_syntax_def_suffix=$(mode_syntax_def_suffix)	

remove-styles:
	@ make -f make_remove-styles.makefile syntax_files="$(syntax_files)" result_files="$(result_files)" \
	xsltproc=$(xsltproc) mode_directory=$(mode_directory) result_mode_directory=$(result_mode_directory) mode_syntax_def_suffix=$(mode_syntax_def_suffix)

create-style-sheet:
	@ make -f make_create-stylesheet.makefile style_files="$(style_files)" style_directory=$(style_directory) \
	xsltproc=$(xsltproc) mode_directory=$(mode_directory) mode_syntax_def_suffix=$(mode_syntax_def_suffix)

style-extraction: create-style-sheet remove-styles
################################################################ Helper Recipes	

### finding the use cases for one scope
find-scope:
	@ ( echo "<modes>"; find $(mode_directory) -name $(syntax_definition) -exec $(xsltproc) --param scope "'$(scope)'" --novalid XMLTagsForScope.xslt \{\} \;; echo "</modes>"; ) | see --mode xml;


### finding all used scopes - one-mode version needs the mode as a param
xslt_scope_in_mode=ScopesInMode.xslt

all-scopes-one-mode:
	@ xsltproc --novalid $(xslt_scope_in_mode) $(mode_directory)$(mode)$(mode_syntax_def_suffix) | see

all-scopes-by-lang:
	@ find $(mode_directory) -name $(syntax_definition) -exec $(xsltproc) --novalid $(xslt_scope_in_mode) \{\} \; | see

all-scopes-uniqued:
	@ find $(mode_directory) -name $(syntax_definition) -exec $(xsltproc) --novalid $(xslt_scope_in_mode) \{\} \; | awk '{print $$1}' | sort | uniq | see


### cleanup - delete style and result files
clean:
	@ for file in $(style_files); do \
		if [ -f $$file ]; then \
	    	rm $$file; \
	    	echo "Removed file:\t$$file"; \
		fi; \
	done;
	@ if [ $(result_mode_directory) != $(mode_directory) ]; then \
		for dir in $(result_mode_mode_directory); do \
			if [ -d $$dir ]; then \
		    	rm -rd $$dir; \
		    	echo "Removed directory:\t$$dir"; \
			fi; \
		done; \
	fi; \
