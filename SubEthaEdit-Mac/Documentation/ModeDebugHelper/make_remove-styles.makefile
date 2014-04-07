# generates a SyntaxDefinition.xml without the style attributes (color etc) from a SyntaxDefinition.xml
### needs param:
## xsltproc
## mode_directory
## result_mode_directory
## mode_syntax_def_suffix
## syntax_files
## result_files
###

xslt=RemoveStyleAttributes.xslt

################################################################ Startup
all: header result_modes
result_modes: $(result_files)

header:
	@ echo "########## Removing style information from SyntaxDefinition.xmls";

################################################################ Recipe
### generating a style-less SyntaxDefinition.xml
# if there is a SyntaxDefinition.xml for that mode
# make the result path dirs (if needed)
# use xslt to generate the new SyntaxDefinition.xml
###

$(result_mode_directory)%$(mode_syntax_def_suffix): $(xslt) force
	@ if [ -s $(mode_directory)$*$(mode_syntax_def_suffix) ]; then \
		mkdir -p "$$(dirname $(result_mode_directory)$*$(mode_syntax_def_suffix))"; \
		$(xsltproc) --novalid $(xslt) $(mode_directory)$*$(mode_syntax_def_suffix) > $(result_mode_directory)$*$(mode_syntax_def_suffix); \
		echo "Created style-less SyntaxDefinition.xml:\t$*"; \
	else \
		echo "No Mode:\t\t$*"; \
	fi


#  adding the following line above the echo in the above if case moves the results to the folder containing the originals
# 		mv $(result_mode_directory)$*$(mode_syntax_def_suffix) $(mode_directory)$*$(mode_syntax_def_suffix); \


# This recipe forces the other recipe to happen every time
force:
