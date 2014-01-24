#README


This readme contains example calls to the *.xslts* created for debugging and improving the *SyntaxDefinition.xmls* contained in a SubEthaEdit-Mode.

---
## XML-Nodes for a special Scope
*ModeDefinitionPerScope.xslt*


Printing all Nodes that contain a certain `scope`-attribute (*eg. `keyword.function`*): 

	xsltproc --param scope-value "'<scope-value>'" --novalid ModeDefinitionPerScope.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see

Printing all Nodes for all modes: 

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --param scope-value "'<scope-value>'" --novalid ModeDefinitionPerScope.xslt \{\} \;

Piping that into SEE and making sure the file is opened in the right mode:

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --param scope-value "'<scope-value>'" --novalid ModeDefinitionPerScope.xslt \{\} \; | see --mode xml
	
Adding a root node to the the resulting XML: 

	( echo "<modes>"; find <path>  -name "SyntaxDefinition.xml" -exec xsltproc --param scope-value "'keyword.function'" --novalid ModeDefinitionPerScope.xslt \{\} \;; echo "</modes>" ) | see --mode xml

---
## All used Scopes in a Mode
*ModeScopes.xslt*

Returning all scopes used by a single Mode (*eg. `PHP-HTML`*):

	xsltproc --novalid ModeScopes.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see

Returning all scopes used by a single Mode:

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid ModeScopes.xslt \{\} \; | see

Returning all scopes used by a single Mode:

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid ModeScopes.xslt \{\} \; | awk '{print $1}' | sort | uniq | see

---
## All values of one Style attribute used in a Mode
*ModeStyles.xslt*

Returning all scope style (*eg. `color`*) values used by a single Mode (*eg. `PHP-HTML`*):

	xsltproc --param style-attribute "'<style-attribute>'" --novalid ModeStyles.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see

Returning all scopes used by a single Mode:

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'<style-attribute>'" --novalid ModeStyles.xslt \{\} \; | see

Returning all scopes used by a single Mode:

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'<style-attribute>'" --novalid ModeStyles.xslt \{\} \; | awk '{print $1}' | sort | uniq | see


---
##PS:
Lisas default Path: `/Users/Lisa/Projects/git/subethaedit/SubEthaEdit-Mac/Modes`  
Coda 2s default Path: `/Applications/Coda 2.app/Contents/Resources`

	xsltproc --param style-attribute "'color'" --novalid ModeStyles.xslt /Users/Lisa/Projects/git/subethaedit/SubEthaEdit-Mac/Modes/AppleScript.mode/Contents/Resources/SyntaxDefinition.xml | see

	find  /Users/Lisa/Projects/git/subethaedit/SubEthaEdit-Mac/Modes -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'color'" --novalid ModeStyles.xslt \{\} \; | awk '{print $1}' | sort | uniq | see

