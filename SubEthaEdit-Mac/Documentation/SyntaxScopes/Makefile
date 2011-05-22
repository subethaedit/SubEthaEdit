#make file for scope documentation and example extraction

XSLTPROC=/usr/bin/xsltproc

LANGUAGES=xml/ScopeExamples.plist css/ScopeExamples.plist
SCOPEDOC=SEEScopeDoc.html

all: doc examples

doc: $(SCOPEDOC)

clean: 
	rm $(LANGUAGES) $(SCOPEDOC)

examples: $(LANGUAGES)

%.html: 
	$(XSLTPROC) ScopeDoc.xslt ScopeDoc.xml > $*.html
	
%/ScopeExamples.plist:
	mkdir -p $*
	$(XSLTPROC) --param lang "'$*'" ScopeExamples.plist.xslt ScopeDoc.xml > $*/ScopeExamples.plist


