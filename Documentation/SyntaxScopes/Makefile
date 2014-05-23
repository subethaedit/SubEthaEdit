#make file for scope documentation and example extraction

XSLTPROC=/usr/bin/xsltproc

LANGUAGES=xml/ScopeExamples.plist css/ScopeExamples.plist js/ScopeExamples.plist html/ScopeExamples.plist coda/ScopeExamples.plist php/ScopeExamples.plist java/ScopeExamples.plist ruby/ScopeExamples.plist
SCOPEDOC=SEEScopeDoc.html

all: doc examples

doc: $(SCOPEDOC)

clean: 
	rm $(LANGUAGES) $(SCOPEDOC)

examples: $(LANGUAGES)

%.html: ScopeDoc.xml ScopeDoc.xslt
	$(XSLTPROC) ScopeDoc.xslt ScopeDoc.xml > $*.html
	
%/ScopeExamples.plist: ScopeDoc.xml ScopeExamples.plist.xslt
	mkdir -p $*
	$(XSLTPROC) --param lang "'$*'" ScopeExamples.plist.xslt ScopeDoc.xml > $*/ScopeExamples.plist


