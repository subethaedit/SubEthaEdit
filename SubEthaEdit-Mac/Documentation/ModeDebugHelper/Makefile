#make file for style sheet creation and style extraction

XSLTPROC=/usr/bin/xsltproc
XSLT=ModeScopeStyles.xslt


LANGUAGES=ActionScript AppleScript ASP-HTML Base bash C C++ CFML Conference CSS Diff ERB erlang go HTML Java Javascript JSP-HTML LassoScript-HTML LaTeX Lua Objective-C Objective-J Pascal Perl PHP-HTML Python Ruby SDEF SQL SVNLog Wiki XML


#debug mode path
MODEPATHPREFIX=/Users/Lisa/Desktop/Modes/

#coda 2 modes
#MODEPATHPREFIX=Coda2Modes/

#MODEPATHPREFIX=../../Modes/
MODEPATHSUFFIX=.mode/Contents/Resources/SyntaxDefinition.xml

STYLEPATHPREFIX=ModeStyles/
STYLEPATHSUFFIX=.sss

STYLES=$(addprefix $(STYLEPATHPREFIX), $(addsuffix $(STYLEPATHSUFFIX), $(LANGUAGES)))
DEFINITONS=$(addprefix $(MODEPATHPREFIX), $(addsuffix $(MODEPATHSUFFIX), $(LANGUAGES)))

#all: styles definitions
all: styles

styles: $(STYLES)
definitions: $(DEFINITONS)

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
	
### init
init:
	mkdir ModeStyles

### cleanup
clean:
	rm $(STYLES) 
