# generates a SyntaxDefinition.xml with a renamed scope from a SyntaxDefinition.xml
### needs param:
## xsltproc
## from
## to
## mode_directory
## (result_mode_directory) // maybe for later use - without instand movment of the file?
## mode_syntax_def_suffix
## syntax_files
###

xslt=RenameScope.xslt

################################################################ Startup
all: header updated_modes
updated_modes: $(syntax_files)

header:
	@ echo "########## Renaming scope $(from) to $(to)";

################################################################ Recipe
### generating a SyntaxDefinition.xml with renamed scope
# if there is a SyntaxDefinition.xml for that mode
# make the result path dirs (if needed)
# use xslt with params from and to to generate the new SyntaxDefinition.xml
# replace the original file with the result file
###

$(mode_directory)%$(mode_syntax_def_suffix): $(xslt) force
	@ if [ -s $(mode_directory)$*$(mode_syntax_def_suffix) ]; then \
		mkdir -p "$$(dirname $(result_mode_directory)$*$(mode_syntax_def_suffix))"; \
		$(xsltproc) --param from "'$(from)'" --param to "'$(to)'" --novalid $(xslt) $(mode_directory)$*$(mode_syntax_def_suffix) > $(result_mode_directory)$*$(mode_syntax_def_suffix); \
		mv $(result_mode_directory)$*$(mode_syntax_def_suffix) $(mode_directory)$*$(mode_syntax_def_suffix); \
		echo "Renamed:\t$*: $(from) to $(to)"; \
	else \
		echo "No Mode:\t\t$*"; \
	fi


# This recipe forces the other recipe to happen every time
force:
