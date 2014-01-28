#make file for style sheet creation and style extraction

XSLTPROC=/usr/bin/xsltproc

# XSLT that generates a sss file from all the used scopes + styles in a SyntaxDefinition.xml
XSLT_STYLESHEET_FROM_MODE=ModeScopeStyles.xslt


# Languages for which to generate a .sss-file : additional languages have to be added by hand
LANGUAGES=ActionScript AppleScript ASP-HTML Base bash C C++ CFML Conference CSS Diff ERB erlang go HTML Java Javascript JSP-HTML LassoScript-HTML LaTeX Lua Objective-C Objective-J Pascal Perl PHP-HTML Python Ruby SDEF SQL SVNLog Wiki XML LESS Sass Smarty YAML


# Path from which to look for mode files
#debug mode path
MODE_PATH_PREFIX=/Users/Lisa/Desktop/Modes/
#coda 2 modes
#MODE_PATH_PREFIX=Coda2Modes/
#MODE_PATH_PREFIX=../../Modes/

#Path that leads to the SyntaxDefinition of a mode
MODE_PATH_SUFFIX=.mode/Contents/Resources/SyntaxDefinition.xml

#Paths to the Style Sheet location
STYLE_PATH_PREFIX=ModeStyles/
STYLE_PATH_SUFFIX=.sss

STYLES=$(addprefix $(STYLE_PATH_PREFIX), $(addsuffix $(STYLE_PATH_SUFFIX), $(LANGUAGES)))
DEFINITONS=$(addprefix $(MODE_PATH_PREFIX), $(addsuffix $(MODE_PATH_SUFFIX), $(LANGUAGES)))

#all: styles definitions
all: styles

styles: $(STYLES)
definitions: $(DEFINITONS)

#generating a style sheet from a SyntaxDefinition.xml
$(STYLE_PATH_PREFIX)%.sss: $(XSLT_STYLESHEET_FROM_MODE)
	@ if [ -s $(MODE_PATH_PREFIX)$*$(MODE_PATH_SUFFIX) ]; then \
		$(XSLTPROC) --novalid $(XSLT_STYLESHEET_FROM_MODE)  $(MODE_PATH_PREFIX)$*$(MODE_PATH_SUFFIX) > $(STYLE_PATH_PREFIX)$*.sss; \
		if [ -s $(STYLE_PATH_PREFIX)$*.sss ]; then \
			echo "Created Style Sheet:\t$*"; \
		else \
			echo "No Style Sheet:\t\t$*"; \
			rm $(STYLE_PATH_PREFIX)$*.sss; \
		fi \
	else \
		echo "No Mode:\t\t$*"; \
	fi
	
### init - make that directory
init:
	mkdir $(STYLE_PATH_PREFIX)

### cleanup - delete all the style files
clean:
	rm $(STYLES) 
