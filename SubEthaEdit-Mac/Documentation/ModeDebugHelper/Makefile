#make file for style sheet creation and style extraction

XSLTPROC=/usr/bin/xsltproc

# XSLT that generates a sss file from all the used scopes + styles in a SyntaxDefinition.xml
XSLT_STYLESHEET_FROM_MODE=ModeScopeStyles.xslt

# XSLT that generates a SyntaxDefinition.xml without the style attributes (color etc) from a SyntaxDefinition.xml
XSLT_REMOVE_STYLEATTRIBUTES_FROM_MODE=ModeRemoveStyles.xslt

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

# Path to store the resulting modes at
MODE_RESULT_PATH_PREFIX=ResultModes/
MODE_RESULT_PATH_SUFFIX=.mode/Contents/Resources/SyntaxDefinition.xml

STYLES=$(addprefix $(STYLE_PATH_PREFIX), $(addsuffix $(STYLE_PATH_SUFFIX), $(LANGUAGES)))
DEFINITONS=$(addprefix $(MODE_PATH_PREFIX), $(addsuffix $(MODE_PATH_SUFFIX), $(LANGUAGES)))
RESULTS=$(addprefix $(MODE_RESULT_PATH_PREFIX), $(addsuffix $(MODE_RESULT_PATH_SUFFIX), $(LANGUAGES)))

all: stylesheader styles resultsheader results

styles: $(STYLES)
definitions: $(DEFINITONS)
results: $(RESULTS)

stylesheader:
	@ echo "########## generating style sheets from SyntaxDefinition.xmls";	

resultsheader:
	@ echo "########## generating style-less SyntaxDefinition.xmls";

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

#generating a style-less SyntaxDefinition.xml
$(MODE_RESULT_PATH_PREFIX)%$(MODE_RESULT_PATH_SUFFIX): $(XSLT_REMOVE_STYLEATTRIBUTES_FROM_MODE)
	@ if [ -s $(MODE_PATH_PREFIX)$*$(MODE_PATH_SUFFIX) ]; then \
		mkdir -p "$$(dirname $(MODE_RESULT_PATH_PREFIX)$*$(MODE_RESULT_PATH_SUFFIX))"; \
		$(XSLTPROC) --novalid $(XSLT_REMOVE_STYLEATTRIBUTES_FROM_MODE)  $(MODE_PATH_PREFIX)$*$(MODE_PATH_SUFFIX) > $(MODE_RESULT_PATH_PREFIX)$*$(MODE_RESULT_PATH_SUFFIX); \
		echo "Created style-less SyntaxDefinition.xml:\t$*"; \
	else \
		echo "No Mode:\t\t$*"; \
	fi	
	
	
### init - make that directory
init:
	@ for dir in $(STYLE_PATH_PREFIX) $(MODE_RESULT_PATH_PREFIX); do \
		if [ -d $$dir ]; then \
			echo "Directory already exists:\t$$dir"; \
		else \
			mkdir $$dir; \
			echo "Created Directory:\t\t$$dir"; \
		fi; \
		done;
	
### cleanup - delete all the style files
clean:
	@ for file in $(STYLES); do \
		if [ -f $$file ]; then \
	    	rm $$file; \
	    	echo "Removed file:\t$$file"; \
		fi; \
	done;
	@ if [ $(MODE_RESULT_PATH_PREFIX) != $(MODE_PATH_PREFIX) ]; then \
		for file in $(RESULTS); do \
			if [ -f $$file ]; then \
		    	rm $$file; \
		    	echo "Removed file:\t$$file"; \
			fi; \
		done; \
	fi; \

