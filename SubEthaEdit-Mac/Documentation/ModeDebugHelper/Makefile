#make file for style sheet creation and style extraction

XSLTPROC=/usr/bin/xsltproc

# XSLT that generates a sss file from all the used scopes + stlyes in a SyntakDefinition.xml
XSLT=ModeScopeStyles.xslt

# Languages for which to generate a .sss-file : additional languages have to be added by hand
LANGUAGES=ActionScript AppleScript ASP-HTML Base bash C C++ CFML Conference CSS Diff ERB erlang go HTML Java Javascript JSP-HTML LassoScript-HTML LaTeX Lua Objective-C Objective-J Pascal Perl PHP-HTML Python Ruby SDEF SQL SVNLog Wiki XML LESS Sass Smarty YAML


# Path from which to look for mode files
#debug mode path
MODEPATHPREFIX=/Users/Lisa/Desktop/Modes/
#coda 2 modes
#MODEPATHPREFIX=Coda2Modes/
#MODEPATHPREFIX=../../Modes/

#Path that leads to the SyntaxDefinition of a mode
MODEPATHSUFFIX=.mode/Contents/Resources/SyntaxDefinition.xml

#Paths to the Style Sheet location
STYLEPATHPREFIX=ModeStyles/
STYLEPATHSUFFIX=.sss

STYLES=$(addprefix $(STYLEPATHPREFIX), $(addsuffix $(STYLEPATHSUFFIX), $(LANGUAGES)))
DEFINITONS=$(addprefix $(MODEPATHPREFIX), $(addsuffix $(MODEPATHSUFFIX), $(LANGUAGES)))

#all: styles definitions
all: styles

styles: $(STYLES)
definitions: $(DEFINITONS)

#generating a style sheet from a SyntaxDefinition.xml
$(STYLEPATHPREFIX)%.sss: $(XSLT)
	@ if [ -s $(MODEPATHPREFIX)$*$(MODEPATHSUFFIX) ]; then \
		$(XSLTPROC) --novalid $(XSLT)  $(MODEPATHPREFIX)$*$(MODEPATHSUFFIX) > $(STYLEPATHPREFIX)$*.sss; \
		if [ -s $(STYLEPATHPREFIX)$*.sss ]; then \
			echo "Created Style Sheet:\t$*"; \
		else \
			echo "No Style Sheet:\t\t$*"; \
			rm $(STYLEPATHPREFIX)$*.sss; \
		fi \
	else \
		echo "No Mode:\t\t$*"; \
	fi
	
### init - make that directory
init:
	mkdir $(STYLEPATHPREFIX)

### cleanup - delete all the style files
clean:
	rm $(STYLES) 
