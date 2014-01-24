#README


This readme contains example calls to the *.xslts* created for debugging and improving the *SyntaxDefinition.xmls* contained in a SubEthaEdit-Mode.

---
## XML-Nodes for a special Scope
**ModeDefinitionPerScope.xslt**


Printing all Nodes that contain a certain `scope`-attribute (*eg. `keyword.function`*) for a single Mode: 

	xsltproc --param scope-value "'<scope-value>'" --novalid ModeDefinitionPerScope.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see

Printing all Nodes for multiple Modes (_opened in SubEthaEdit in XML-Mode_): 

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --param scope-value "'<scope-value>'" --novalid ModeDefinitionPerScope.xslt \{\} \; | see --mode xml
	
Adding a root node to the the resulting XML: 

	( echo "<modes>"; find <path>  -name "SyntaxDefinition.xml" -exec xsltproc --param scope-value "'keyword.function'" --novalid ModeDefinitionPerScope.xslt \{\} \;; echo "</modes>" ) | see --mode xml

---
## All used Scopes in a Mode
**ModeScopes.xslt**

Returning all scopes used by a single Mode (*eg. `PHP-HTML`*):

	xsltproc --novalid ModeScopes.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see

Returning all scopes used by multiple Modes:

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid ModeScopes.xslt \{\} \; | see

Returning all scopes used by multiple Modes - sorted:

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid ModeScopes.xslt \{\} \; | awk '{print $1}' | sort | uniq | see

---
## All values of one Style attribute used in a Mode
**ModeStyles.xslt**

Returning all scope-styles (*eg. `color`*) used by a single Mode (*eg. `PHP-HTML`*) (_opened in SubEthaEdit in CSS-Mode_):

	xsltproc --param style-attribute "'<style-attribute>'" --novalid ModeStyles.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see --mode css

Returning all scope styles used by multiple Modes (*eg. `PHP-HTML`*):

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'<style-attribute>'" --novalid ModeStyles.xslt \{\} \; | awk '{print $1}' | sort | uniq | see --mode css


---
##PS:
Lisas default Path: `/Users/Lisa/Projects/git/subethaedit/SubEthaEdit-Mac/Modes`  
Coda 2s default Path: `/Applications/Coda 2.app/Contents/Resources`


Lisa (ghost)-specific examples for **ModeStyles.xslt** :

	xsltproc --param style-attribute "'inverted-color'" --novalid ModeStyles.xslt /Users/Lisa/Projects/git/subethaedit/SubEthaEdit-Mac/Modes/AppleScript.mode/Contents/Resources/SyntaxDefinition.xml | see --mode css

	find  /Users/Lisa/Projects/git/subethaedit/SubEthaEdit-Mac/Modes -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'inverted-color'" --novalid ModeStyles.xslt \{\} \; | sort | uniq | see --mode css

