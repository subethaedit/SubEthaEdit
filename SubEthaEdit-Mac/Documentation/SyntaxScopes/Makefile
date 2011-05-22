#make file for scope documentation and example extraction

XSLTPROC=/usr/bin/xsltproc

LANGUAGES=xml/ScopeExamples.plist

all: doc examples

doc: SEEScopeDoc.html

examples: $(LANGUAGES)

%.html: 
	$(XSLTPROC) ScopeDoc.xslt ScopeDoc.xml > $*.html
	
%/ScopeExamples.plist:
	mkdir -p $*
	$(XSLTPROC) --param lang "'$*'" ScopeExamples.plist.xslt ScopeDoc.xml > $*/ScopeExamples.plist


