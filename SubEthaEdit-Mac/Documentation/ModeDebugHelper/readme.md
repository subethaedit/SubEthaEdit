#README


This readme contains example calls to the *.xslts* created for debugging and improving the *SyntaxDefinition.xmls* contained in a SubEthaEdit/Coda2-Mode.

Overview:

1. [All XML-Nodes using a scope](#xmlForScope)
2. [All Scopes used in a Mode](#scopes)
3. [Simple Style Sheet for one style attribute](#oneStyleAttribute)
4. [Simple Style Sheet for all style attributes](#allStyleAttributes)
5. [Remove style attributes from Mode](#removeStyleAttributes)
6. [Rename Scope](#renameScope)
7. [Style Extraction Makefile](#makefile)

---
## [All XML-Nodes using a Scope](id:xmlForScope)
**XMLTagsForScope.xslt**

Printing all XML-Nodes that are a certain `scope` (*eg. `keyword.function`*) for a single Mode (_opened in SubEthaEdit in XML-Mode_): 

	xsltproc --param scope "'<scope>'" --novalid XMLTagsForScope.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see --mode xml

Printing all XML-Nodes for multiple Modes: 

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --param scope "'<scope>'" --novalid XMLTagsForScope.xslt \{\} \; | see --mode xml
	
Adding a root node to the the resulting XML: 

	( echo "<modes>"; find <path>  -name "SyntaxDefinition.xml" -exec xsltproc --param scope "'<scope>'" --novalid XMLTagsForScope.xslt \{\} \;; echo "</modes>" ) | see --mode xml

---
## [All Scopes used in a Mode](id:scopes)
**ScopesInMode.xslt**

Returning all scopes used in a single Mode (*eg. `PHP-HTML`*):

	xsltproc --novalid ScopesInMode.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see

Returning all scopes used by multiple Modes:

	find <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid ScopesInMode.xslt \{\} \; | see

Returning all scopes used by multiple Modes - sorted and uniqued:

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid ScopesInMode.xslt \{\} \; | awk '{print $1}' | sort | uniq | see

---
## [Simple Style Sheet for one style attribute](id:oneStyleAttribute)
**StyleSheetForAttribute.xslt**

Returning a style sheet for a scope style (*eg. `color`*) used by a single Mode (*eg. `PHP-HTML`*) (_opened in SubEthaEdit in CSS-Mode_):

	xsltproc --param style-attribute "'<style-attribute>'" --novalid StyleSheetForAttribute.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see --mode css

Returning a style sheet for a scope style used by multiple Modes - sorted:

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'<style-attribute>'" --novalid StyleSheetForAttribute.xslt \{\} \; | sort | uniq | see --mode css

---
## [Simple Style Sheet for all style attributes](id:allStyleAttributes)
**StyleSheetForAllAttributes.xslt**

Returning a style sheet for all scope styles (`color, inverted-color, background-color, inverted-background-color, font-trait, font-weight, font-style`) used by a single Mode (*eg. `PHP-HTML`*) (_opened in SubEthaEdit in CSS-Mode_):

	xsltproc --novalid StyleSheetForAllAttributes.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see --mode css

Returning a style sheet for all scope styles used by multiple Modes - sorted:

	find  <path> -name "SyntaxDefinition.xml" -exec xsltproc --novalid StyleSheetForAllAttributes.xslt \{\} \; | sort | see --mode css

---
## [Remove style attributes from Mode](id:removeStyleAttributes)
**RemoveStyleAttributes.xslt**

Removing all style attributes (`color, inverted-color, background-color, inverted-background-color, font-trait, font-weight, font-style` from a Mode (*eg. `PHP-HTML`*) (_opened in SubEthaEdit in XML-Mode_):

	xsltproc --novalid RemoveStyleAttributes.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see --mode xml

---
## [Rename Scope](id:renameScope)
**RenameScope.xslt**

Renaming a scope (*eg. `meta.default`*) in a single Mode (*eg. `PHP-HTML`*) (_opened in SubEthaEdit in XML-Mode_):

	xsltproc --param from "'<scope-value>'" --param to "'<new-scope-value>'" --novalid RenameScope.xslt <path>/<mode-name>.mode/Contents/Resources/SyntaxDefinition.xml | see --mode xml

---
## [Style Extraction Makefile](id:makefile)
**Makefile**

`make` : generates Style Sheets and SyntaxDefinition.xmls without style information  
`make MODE_PATH_PREFIX=<path/to/Modes/Folder/>` generates style sheets and xml for the Modes in given folder  
`make STYLE_PATH_PREFIX=<path/to/Style/Folder/>` generates the Style Sheets in the given folder  
`make MODE_RESULT_PATH_PREFIX=<path/to/Result/Mode/Folder/>` generates the SyntaxDefinition.xmls in the given folder  
`make clean` : deletes all the generated .sss files and .mode directories  

For more information about this Makefile drop it onto the text editor of your choice and have fun.

---
##PS: Examples
Modes - SEE - relative path in repository: `../../Modes`  
Modes - Coda2 - relative path in repository: `Coda2Modes/`  

* Examples for **XMLTagsForScope.xslt**
	
		xsltproc --param scope "'language.operator'" --novalid XMLTagsForScope.xslt Coda2Modes/PHP-HTML.mode/Contents/Resources/SyntaxDefinition.xml | see --mode xml
	
		find Coda2Modes/ -name "SyntaxDefinition.xml" -exec xsltproc --param scope "'language.operator'" --novalid XMLTagsForScope.xslt \{\} \; | see --mode xml
	
		( echo "<modes>"; find Coda2Modes/ -name "SyntaxDefinition.xml" -exec xsltproc --param scope "'language.operator'" --novalid XMLTagsForScope.xslt \{\} \;; echo "</modes>" ) | see --mode xml

	
* Examples for **ScopesInMode.xslt**
		
		xsltproc --novalid ScopesInMode.xslt Coda2Modes/PHP-HTML.mode/Contents/Resources/SyntaxDefinition.xml | see

		find Coda2Modes/ -name "SyntaxDefinition.xml" -exec xsltproc --novalid ScopesInMode.xslt \{\} \; | see

		find Coda2Modes/ -name "SyntaxDefinition.xml" -exec xsltproc --novalid ScopesInMode.xslt \{\} \; | awk '{print $1}' | sort | uniq | see
		

* Examples for **StyleSheetForAttribute.xslt**

		xsltproc --param style-attribute "'background-color'" --novalid StyleSheetForAttribute.xslt Coda2Modes/ASP-HTML.mode/Contents/Resources/SyntaxDefinition.xml | see --mode css

		find Coda2Modes/ -name "SyntaxDefinition.xml" -exec xsltproc --param style-attribute "'background-color'" --novalid StyleSheetForAttribute.xslt \{\} \; | sort | uniq | see --mode css
	

* Examples for **StyleSheetForAllAttributes.xslt**

		xsltproc --novalid StyleSheetForAllAttributes.xslt Coda2Modes/ASP-HTML.mode/Contents/Resources/SyntaxDefinition.xml | see --mode css

		find Coda2Modes -name "SyntaxDefinition.xml" -exec xsltproc --novalid StyleSheetForAllAttributes.xslt \{\} \; | sort | see --mode css
	

* Examples for **RemoveStyleAttributes.xslt**

		xsltproc --novalid RemoveStyleAttributes.xslt Coda2Modes/ASP-HTML.mode/Contents/Resources/SyntaxDefinition.xml | see --mode xml

* Examples for **RenameScope.xslt**
 
		xsltproc --param from "'meta.default'" --param to "'magic.bullet'" --novalid RenameScope.xslt Coda2Modes/PHP-HTML.mode/Contents/Resources/SyntaxDefinition.xml | see --mode xml

