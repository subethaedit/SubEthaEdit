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
## plist_result_directory
## mode_plist_suffix
## plist_files
## plist_result_files
###
## from
## to
## scope
## mode
## key
## to
###

xsltproc=/usr/bin/xsltproc

# languages for which to generate a .sss-file : additional languages have to be added by hand - the last line are coda 2 modes that are not included in SEE (so far)
languages=ActionScript AppleScript ASP-HTML \
			Base bash \
			C C++ CFML Conference CSS \
			Diff \
			ERB erlang \
			go \
			HTML \
			Java Javascript JSP-HTML \
			LassoScript-HTML LaTeX Lua \
			Objective-C Objective-J \
			Pascal Perl PHP-HTML Python \
			Ruby \
			SDEF SQL SVNLog \
			Wiki \
			XML \
			LESS Sass Smarty YAML

################################################################ Paths

## Path from which to look for mode files
#debug mode path
mode_directory=../../SubEthaEdit-Mac/Modes/
#mode_directory=../../Modes-Website/
#mode_directory=Coda2Modes/
#mode_directory=ResultModes/

## Directory to store the resulting modes at
result_mode_directory=ResultModes/
#result_mode_directory=/Users/Lisa/Desktop/Modes/

## Path that leads to the SyntaxDefinition of a mode
mode_syntax_def_suffix=.seemode/Contents/Resources/SyntaxDefinition.xml

## File name SyntaxDefinition
syntax_definition="SyntaxDefinition.xml"

## Paths to the Style Sheet location
style_directory=ModeStyles/

## Plist related paths
plist_result_directory=ModePlists/
mode_plist_suffix=.seemode/Contents/Info.plist

##
style_files=$(addprefix $(style_directory), $(addsuffix .sss, $(languages)))
syntax_files=$(addprefix $(mode_directory), $(addsuffix $(mode_syntax_def_suffix), $(languages)))
result_files=$(addprefix $(result_mode_directory), $(addsuffix $(mode_syntax_def_suffix), $(languages)))
result_mode_mode_directory=$(addprefix $(result_mode_directory), $(addsuffix ".seemode", $(languages)))

##
plist_files=$(addprefix $(mode_directory), $(addsuffix $(mode_plist_suffix), $(languages)))
plist_result_files=$(addprefix $(plist_result_directory), $(addsuffix $(mode_plist_suffix), $(languages)))
plist=Info.plist

## Outside Parameter
from=meta.default
to=meta.default
scope=language.subroutine
mode=PHP-HTML

################################################################ Startup

all: help

help:
	@ bold=`tput bold`; \
	normal=`tput sgr0`; \
    echo  " ################################## HOW-TO ##################################                                                      \n" \
            "                                                                                                                                 \n" \
            " This Makefile acts as a umbrella makefile, using other makefiles to do the actual work.                                         \n" \
            " The following options are available:                                                                                            \n" \
            "                                                                                                                                 \n" \
            " $${bold}make$${normal} and $${bold}make help$${normal} : prints a short how-to                                                  \n" \
            "                                                                                                                                 \n" \
            " $${bold}make create-style-sheet$${normal} generates style sheets from the style info in the definition files                    \n" \
            " $${bold}make create-style-sheet mode_directory=<path/to/Modes/Folder/>$${normal} generates style sheets for the modes in folder \n" \
            " $${bold}make create-style-sheet style_directory=<path/to/Style/Folder/>$${normal} generates style sheets in folder              \n" \
            "                                                                                                                                 \n" \
            " $${bold}make remove-styles$${normal} generates SyntaxDefinition.xmls without style information                                  \n" \
            " $${bold}make remove-styles mode_directory=<path/to/Modes/Folder/>$${normal} generates new xml for the modes in folder           \n" \
            " $${bold}make remove-styles result_mode_directory=<path/to/Result/Mode/Folder/>$${normal} generates new xml in folder            \n" \
            "                                                                                                                                 \n" \
            " $${bold}make style-extraction$${normal} calls both create-style-sheet and remove-styles for one step extraction                 \n" \
            "                                                                                                                                 \n" \
            " $${bold}make rename from=<scope> to=<scope>$${normal} generates new xml in results folder with renamed scopes                   \n" \
            "                                                                                                                                 \n" \
            " $${bold}make update-plist key=<key> to=<value>$${normal} generates new plist in results folder with changed value               \n" \
            " $${bold}make sort-plist$${normal} generates sorted plist in results folder - removing unknown keys                              \n" \
            "                                                                                                                                 \n" \
            " $${bold}make plist-values key=<key>$${normal} generates a list of the values used for the given key                             \n" \
            " $${bold}make all-plist-values$${normal} generates a list of the values used for all the keys                                    \n" \
            "                                                                                                                                 \n" \
            " $${bold}make find-scope scope=<scope>$${normal} generates a xml files containing all the uses of <scope>                        \n" \
            " $${bold}make all-scopes-one-mode mode=<mode>$${normal} generates an annotated txt with scopes used by a mode                    \n" \
            " $${bold}make all-scopes-by-lang$${normal} generates an annotated txt with scopes used by all modes                              \n" \
            " $${bold}make all-scopes-uniqued$${normal} generates a txt with sorted scopes used by all modes                                  \n" \
            "                                                                                                                                 \n" \
            " $${bold}make clean$${normal} deletes all the generated .sss files and result .seemode directories                               \n" \
            "                                                                                                                                 \n" \
            " ** For more information about this Makefile drop it onto the text editor of your choice and have fun. **                        \n";

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

update-plist:
	@ make -f make_update-plist.makefile key=$(key) to=$(to) plist_files="$(plist_files)" plist_result_files="$(plist_result_files)" \
	xsltproc=$(xsltproc) mode_directory=$(mode_directory) plist_result_directory=$(plist_result_directory) mode_plist_suffix=$(mode_plist_suffix)

sort-plist:
	@ make -f make_sort-plist.makefile plist_files="$(plist_files)" plist_result_files="$(plist_result_files)" \
	xsltproc=$(xsltproc) mode_directory=$(mode_directory) plist_result_directory=$(plist_result_directory) mode_plist_suffix=$(mode_plist_suffix)

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

### plist helper
plist-values:
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'$(key)'" --novalid PlistValueForKey.xslt \{\} \; | see

all-plist-values:
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundleIdentifier'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundleName'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'NSHumanReadableCopyright'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundleGetInfoString'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundleShortVersionString'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundleVersion'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'SEEMinimumEngineVersion'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundlePackageType'" --novalid PlistValueForKey.xslt \{\} \; | see;
	@ find $(mode_directory) -name $(plist) -exec $(xsltproc) --param key "'CFBundleInfoDictionaryVersion'" --novalid PlistValueForKey.xslt \{\} \; | see;
	
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
