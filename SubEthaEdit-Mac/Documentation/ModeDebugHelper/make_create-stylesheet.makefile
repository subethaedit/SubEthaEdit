# generates a SyntaxDefinition.xml without the style attributes (color etc) from a SyntaxDefinition.xml
### needs param:
## xsltproc
## mode_directory
## mode_syntax_def_suffix
## style_directory
## style_files
###

#xslt=StyleSheetForAllAttributes.xslt
xslt=StyleSheetForAllAttributesFormated.xslt

################################################################ Startup
all: header styles
styles: $(style_files)

header:
	@ echo "########## Generating style sheets from SyntaxDefinition.xmls";
	mkdir -p $(style_directory);

################################################################ Recipe
### generating a .sss file from all the used scopes + styles in a SyntaxDefinition.xml
# if there is a SyntaxDefinition.xml for that mode
# make the result path dirs (if needed)
# use xslt to generate the new SyntaxDefinition.xml
###

$(style_directory)%.sss: $(xslt) force
	@ if [ -s $(mode_directory)$*$(mode_syntax_def_suffix) ]; then \
		$(xsltproc) --novalid $(xslt) $(mode_directory)$*$(mode_syntax_def_suffix) > $(style_directory)$*.sss; \
		if [ -s $(style_directory)$*.sss ]; then \
			echo "Created Style Sheet:\t$*"; \
		else \
			echo "No Style Sheet:\t\t$*"; \
			rm $(style_directory)$*.sss; \
		fi \
	else \
		echo "No Mode:\t\t$*"; \
	fi

# This recipe forces the other recipe to happen every time
force:
