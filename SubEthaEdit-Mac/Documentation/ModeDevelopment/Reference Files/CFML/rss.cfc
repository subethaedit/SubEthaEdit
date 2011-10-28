<!---
	Name         : rss.cfc
	Version		 : 0.1
	Author       : Raymond Camden 
	Created      : December 8, 2004
	Last Updated : February 7, 2007
	History      : Fix for bug with isSimpleValue barfing on a string with xml (rkc 1/5/05)
				   Added generation code (rkc last few weeks)
				   Don't use GUID if permalink is false (rkc 10/17/06)
				   Fixed bugs in Atom support. Added support for standard enclosures. (bpr 2/7/06)
	Purpose		 : General handler for RSS data.
	
	Note: I cannot give enough thanks to Roger B. (roger@agincourtmedia.com). He was
	an incredible amount of help in turning this from a toy to something that actually
	worked well and followed the standards (although I didn't go quite as far as I could).
	
	Note: Various methods have output=true on them. This is to help debug. They will be turned
	off once I hit 1.0.
		
	To Do:
		generateRSS() (obvious)
--->
<cfcomponent displayName="RSS" hint="Allows for various ways to handle RSS data." output="false">

<!---
<!--- Used for the default query --->
<cfset variables.defaultQueryList = "title,description,link,date,enclosure,categories">
--->

<cffunction name="init" access="public" returntype="rss" hint="construct, added to allow this cfc to work as a service">
	<cfreturn this>
</cffunction>

<cffunction name="generateRSS" access="public" returnType="string" output="true"
			hint="Translates a query into RSS.">
	<cfargument name="type" type="string" required="true" hint="RSS Type: RSS091,RSS092,RSS1,RSS2, or Atom3">
	<cfargument name="data" type="query" required="true" hint="Query with columns: link,title,body,date,subject">
	<cfargument name="metadata" type="struct" required="true" hint="Struct used for metadata">
	
	<!--- default query cols --->
	<cfif not listFindNoCase(arguments.data.columnList,"link")>
		<cfset queryAddColumn(arguments.data,"link",arrayNew(1))>
	</cfif>
	<cfif not listFindNoCase(arguments.data.columnList,"title")>
		<cfset queryAddColumn(arguments.data,"title",arrayNew(1))>
	</cfif>
	<cfif not listFindNoCase(arguments.data.columnList,"body")>
		<cfset queryAddColumn(arguments.data,"body",arrayNew(1))>
	</cfif>
	<cfif not listFindNoCase(arguments.data.columnList,"date")>
		<cfset queryAddColumn(arguments.data,"date",arrayNew(1))>
	</cfif>
	<cfif not listFindNoCase(arguments.data.columnList,"subject")>
		<cfset queryAddColumn(arguments.data,"subject",arrayNew(1))>
	</cfif>
	
	<cfif arguments.type is "RSS091">
		<cfreturn generateRSS_RSS(arguments.data, arguments.metadata,"0.91")>
	<cfelseif arguments.type is "RSS092">
		<cfreturn generateRSS_RSS(arguments.data, arguments.metadata,"0.92")>
	<cfelseif arguments.type is "RSS1">
		<cfreturn generateRSS_RSS1(arguments.data, arguments.metadata)>
	</cfif>
	
</cffunction>

<cffunction name="generateRSS_RSS" access="private" returnType="string" output="true"
			hint="Translates a query into RSS. This is used for RSS 0.91 and RSS 0.92">
	<cfargument name="data" type="query" required="true" hint="Query with columns: link,title,body,date,subject,categories">
	<cfargument name="metadata" type="struct" required="true" hint="Struct with keys: title,link,description">
	<cfargument name="version" type="string" required="true" hint="0.91, or 0.92">
	<cfset var header = "">
	<cfset var footer = "">
	<cfset var meta = "">
	<cfset var body = "">
	<cfset var tBody = "">
	<cfset var result = "">
	<cfset var cat = "">
	
	<cfsavecontent variable="header">
	<cfoutput>
	<?xml version="1.0" encoding="ISO-8859-1" ?>
	<rss version="#arguments.version#">
	<channel>
	</cfoutput>
	</cfsavecontent>
	
	<cfsavecontent variable="footer">
	<cfoutput>
	</channel>
	</rss>
	</cfoutput>
	</cfsavecontent>

	<!--- first handle metadata --->
	<cfset meta = renderMeta(arguments.metadata)>
	
	<cfloop query="arguments.data">
		<cfsavecontent variable="tBody">
		<cfoutput>
		<item>
		<title>#xmlFormat(arguments.data.title)#</title> 
		<link>#xmlFormat(arguments.data.link)#</link> 
		<description>#xmlFormat(arguments.data.body)#</description>
		<cfif arguments.version is 0.92><category>#xmlFormat(arguments.data.subject)#</category></cfif>
		<cfloop list="#arguments.data.categories#" index="cat"><category>#xmlFormat(cat)#</category></cfloop>
		</item>
		</cfoutput>
		</cfsavecontent>
		<cfset body = body & tBody>
	</cfloop>
	
	<cfset result = trim(header) & trim(meta) & trim(body) & trim(footer)>
	<cfreturn result>
	
</cffunction>

<cffunction name="generateRSS_RSS1" access="private" returnType="string" output="true"
			hint="Translates a query into RSS. This is used for RSS 1.0">
	<cfargument name="data" type="query" required="true" hint="Query with columns: link,title,body,date,subject">
	<cfargument name="metadata" type="struct" required="true" hint="Struct with keys: title,link,description">
	<cfset var header = "">
	<cfset var footer = "">
	<cfset var meta = "">
	<cfset var body = "">
	<cfset var tBodyTop = "">
	<cfset var tBodyBottom = "">
	<cfset var result = "">
	<cfset var z = getTimeZoneInfo()>
	
	<cfsavecontent variable="header">
	<cfoutput>
	<?xml version="1.0" encoding="ISO-8859-1" ?>
	<rdf:RDF 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns="http://purl.org/rss/1.0/"
	>
	</cfoutput>
	</cfsavecontent>
	
	<cfsavecontent variable="footer">
	<cfoutput>
	</rdf:RDF> 
	</cfoutput>
	</cfsavecontent>

	<!--- first handle metadata --->
	<cfset meta = renderMeta(arguments.metadata)>
	
	<!--- We loop through twice, once for top portion, one for body portion --->
	<cfloop query="arguments.data">
		<cfsavecontent variable="tBodyTop">
		<cfoutput>
		<rdf:li rdf:resource="#xmlFormat(arguments.data.link)#" />
		</cfoutput>
		</cfsavecontent>
		<cfset body = body & tBodyTop>
	</cfloop>
	
	<!--- Mody body to correctly wrap content. --->
	<cfsavecontent variable="body">
		<cfoutput>
		<cfif structKeyExists(arguments.metadata,"link")>
			<channel rdf:about="#xmlFormat(arguments.metadata.link)#">
		<cfelse>
			<channel rdf:about="">
		</cfif>
		#trim(meta)#
		<items>
		<rdf:Seq>
		#body#
		</rdf:Seq>
		</items>
		</channel>
		</cfoutput>
	</cfsavecontent>

	<!--- Now handle the next portion of the body --->
	<cfloop query="arguments.data">
		<cfsavecontent variable="tBodyBottom">
		<cfoutput>
	  	<item rdf:about="#xmlFormat(arguments.data.link)#">
		<title>#xmlFormat(arguments.data.title)#</title>
		<description>#xmlFormat(arguments.data.body)#</description>
		<link>#xmlFormat(arguments.data.link)#</link>
		<dc:date>#dateFormat(arguments.data.date,"yyyy-mm-dd")#T#timeFormat(arguments.data.date,"HH:mm:ss")#<cfif z.utcHourOffSet lt 0>+#numberFormat(z.utcHourOffset,"00")*-1#<cfelse>-#numberFormat(z.utcHourOffset,"00")#</cfif>:00</dc:date>
		<dc:subject>#xmlFormat(arguments.data.subject)#</dc:subject>
		<cfloop list="#arguments.data.categories#" index="cat"><category>#xmlFormat(cat)#</category></cfloop>
		</item>
		</cfoutput>
		</cfsavecontent>
		<cfset body = body & trim(tBodyBottom)>
	</cfloop>
	
	<cfset result = trim(header) & trim(body) & trim(footer)>
	<cfreturn result>
	
</cffunction>

<cffunction name="getEntries" access="public" returnType="query" output="true"
			hint="Translates a RSS feed into a simple query.">
	<cfargument name="xmlData" type="any" required="true" hint="XML Ob, XML String, or URL">
	<cfset var rssType = "">
	<cfset var result = queryNew(variables.defaultQueryList)>

	<cfset arguments.xmlData = getXML(arguments.xmlData)>
	<cfset rssType = getRssType(arguments.xmlData)>

	<!--- What we do is determined by the type --->
	<cfswitch expression="#rssType.type#">
	
		<cfcase value="rss">
			<cfreturn getEntriesRSS(arguments.xmlData)>
		</cfcase>
		
		<cfcase value="atom">
			<cfreturn getEntriesAtom(arguments.xmlData)>
		</cfcase>
		
		<cfdefaultcase>
			<cfreturn result>
		</cfdefaultcase>
		
	</cfswitch>
	
</cffunction>

<cffunction name="getEntriesAtom" access="private" returnType="query" output="true"
			hint="Handles Atom feeds">
	<cfargument name="xmlData" type="any" required="true" hint="XML Ob">

	<cfset var entries = "">
	<cfset var result = queryNew(variables.defaultQueryList)>
	<cfset var x = 1>
	<cfset var i = 1>
	<cfset var node = "">
	
	<cfset entries = xmlSearch(arguments.xmlData,"//*[local-name() = 'entry']")>

	<cfloop index="x" from="1" to="#arrayLen(entries)#">
		<cfset node = structNew()>
		<cfset node.title = entries[x].title.xmlText>
		<!--- Link comes from entries[x].link.XmlAttributes.rel --->
		<cfset node.link = "">
		<cfset node.enclosure = "">
		<cfif structKeyExists(entries[x],"link")>
			<!--- loop through N links --->
			<cfloop index="i" from="1" to="#arrayLen(entries[x].link)#">
				<cfif entries[x].link[i].xmlAttributes.rel is "alternate">
					<cfset node.link = entries[x].link[i].xmlAttributes.href>
				<cfelseif entries[x].link[i].xmlAttributes.rel is "enclosure">
					<cfset node.enclosure = entries[x].link[i].xmlAttributes.href>
				</cfif>
			</cfloop>
		</cfif>
		<!--- try for summary first --->
		<cfif structKeyExists(entries[x],"summary")>
			<cfset node.description = entries[x].summary.xmlText>		
		<cfelseif structKeyExists(entries[x],"content")>
			<!--- handle potential xml content --->
			<cfif structKeyExists(entries[x].content.xmlAttributes,"mode") and entries[x].content.xmlAttributes.mode is "xml">
				<cfset node.description = getEmbeddedHTML(entries[x].content.xmlChildren)>
			<cfelse>
				<cfset node.description = entries[x].content.xmlText>
			</cfif>
		<cfelse>
			<cfset node.description = "">
		</cfif>
		<cfif structKeyExists(entries[x],"published")>
			<cfset node.date = entries[x].published.xmlText>
		<cfelseif structKeyExists(entries[x],"updated")>
			<cfset node.date = entries[x].updated.xmlText>
		<cfelse>
			<cfset node.date = "">
		</cfif>
		
		<cfset queryAddRow(result)>
		<cfset querySetCell(result,"title",node.title)>
		<cfset querySetCell(result,"description",node.description)>
		<cfset querySetCell(result,"link",node.link)>
		<cfset querySetCell(result,"enclosure",node.enclosure)>
		<cfset querySetCell(result,"date",node.date)>

	</cfloop>

	<cfreturn result>	

</cffunction>

<cffunction name="getEntriesRSS" access="private" returnType="query" output="true"
			hint="Handles RSS feeds">
	<cfargument name="xmlData" type="any" required="true" hint="XML Ob">
	
	<cfset var items = "">
	<cfset var result = queryNew(variables.defaultQueryList)>
	<cfset var x = 1>
	<cfset var node = "">
	<cfset var xmlNode = 0>
	<cfset var y = 1>
	
	<cfset items = xmlSearch(arguments.xmlData,"//*[local-name() = 'item']")>
		
	<cfloop index="x" from="1" to="#arrayLen(items)#">
		<cfscript>
			node = structNew();
			node.title = "";
			node.description = "";
			node.link = "";
			node.enclosure = "";
			node.date = "";
			node.categories = "";
			
			for(y=1;y lte arrayLen(items[x].xmlChildren);y=y+1) {
			
				xmlNode = items[x].xmlChildren[y];
			
				switch(xmlNode.xmlName) {
				
					case "title":
						node.title = xmlNode.XmlText;
						break;
						
					case "description":
						node.description = xmlNode.XmlText;
						break;	
					
					case "guid":
						if(not structKeyExists(xmlNode.xmlAttributes, "isPermaLink") 
								or xmlNode.xmlAttributes.isPermaLink) {
							node.link = xmlNode.XmlText;	
						}
				
					case "link":
						node.link = xmlNode.XmlText;
						break;
						
					case "source":
						if(structKeyExists(xmlNode.XmlAttributes,"url"))
							node.link = xmlNode.XmlAttributes.url;
						break;
						
					case "enclosure":
						if(structKeyExists(xmlNode.XmlAttributes,"url"))
							node.enclosure = xmlNode.XmlAttributes.url;
						break;
						
					case "pubdate":
						node.date = xmlNode.XmlText;
						break;
					
					case "dc:date":
						node.date = xmlNode.XmlText;
						break;
						
					case "category":
						node.categories = listAppend(node.categories, xmlNode.XmlText );	
						break;
						
				}
			}
			
			queryAddRow(result);
			querySetCell(result,"title",node.title);
			querySetCell(result,"description",node.description);
			querySetCell(result,"link",node.link);
			querySetCell(result,"date",node.date);
			querySetCell(result,"categories",node.categories);
		</cfscript>		
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="getRSSMeta" access="public" returnType="struct" output="true"
			hint="Gets meta info on an RSS feed.">
	<cfargument name="xmlData" type="any" required="true" hint="XML Ob, XML String, or URL">
	<cfset var result = structNew()>
	<cfset var rssType = "">
	
	<cfset arguments.xmlData = getXML(arguments.xmlData)>
	<cfset rssType = getRSSType(arguments.xmlData)>

	<!--- What we do is determined by the type --->
	<cfswitch expression="#rssType.type#">
	
		<cfcase value="rss">
			<cfif rssType.version is 2>
				<cfreturn getRSSMetaRss2(arguments.xmlData)>
			<cfelseif rssType.version is 0.91>
				<cfreturn getRSSMetaRss09(arguments.xmlData)>
			<cfelseif rssType.version is 0.92>
				<cfreturn getRSSMetaRss09(arguments.xmlData,"0.92")>
			<cfelseif rssType.version is 1>
				<cfreturn getRSSMetaRss1(arguments.xmlData)>
			</cfif>
		</cfcase>
		
		<cfcase value="atom">
			<cfreturn getRssMetaAtom(arguments.xmlData)>
		</cfcase>
		
		<cfdefaultcase>
			<cfreturn result>
		</cfdefaultcase>
		
	</cfswitch>
	
	<cfreturn result>
</cffunction>

<cffunction name="getRSSMetaAtom" access="private" returnType="struct" output="true"
			hint="Gets meta info for Atom feeds.">
	<cfargument name="xmlData" type="any" required="true" hint="XML object.">
	
	<cfset var result = structNew()>
	<cfset var reqList = "title,link,author,modified">
	<cfset var optList = "contributor,tagline,id,generator,copyright,info">
	<cfset var key = "">
	<cfset var x = "">

	<!--- required items --->
	<cfloop index="key" list="#reqList#">
		<cfif not structKeyExists(arguments.xmlData.feed,key)>
			<cfset result[key] = "">
		<cfelse>
			<cfif key is "link">
				<!--- we only want the rel/alternate link --->
				<cfloop index="x" from="1" to="#arrayLen(arguments.xmlData.feed.link)#">
					<cfif arguments.xmlData.feed.link[x].XmlAttributes.rel is "alternate">
						<cfset result["link"] = arguments.xmlData.feed.link[x].XmlAttributes.href>
					</cfif>
				</cfloop>
			<cfelseif key is "author">
				<cfset result["author"] = arguments.xmlData.feed.author.name.XmlText>
			<cfelse>
				<cfset result[key] = arguments.xmlData.feed[key].XmlText>
			</cfif>
		</cfif>		
	</cfloop>

	<!--- optional items --->
	<cfloop index="key" list="#optList#">
		<cfif structKeyExists(arguments.xmlData.feed,key)>
			<cfif key is "info">
				<cfset result[key] = arguments.xmlData.feed.info.XmlChildren[1].toString()>
			<cfelse>
				<cfset result[key] = arguments.xmlData.feed[key].XmlText>
			</cfif>
		</cfif>		
	</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getRSSMetaRss09" access="private" returnType="struct" output="true"
			hint="Gets meta info for RSS 0.91 and 0.92 feeds.">
	<cfargument name="xmlData" type="any" required="true" hint="XML object.">
	<cfargument name="version" type="string" required="false" default="0.91" hint="Version">
	
	<cfset var result = structNew()>
	<cfset var reqList = "title,link,description,language">
	<cfset var optList = "copyright,docs,image,lastBuildDate,managingEditor,pubDate,rating,skipDays,skipHours,textinput,webMaster">
	<cfset var key = "">
	<cfset var i = "">
	
	<!--- modify reqList if version is 0.92 --->
	<cfif arguments.version is 0.92>
		<cfset reqList = listDeleteAt(reqList, listFindNoCase(reqList, "language"))>
		<cfset optList = listAppend(optList, "language")>
	</cfif>
			
	<!--- required items --->
	<cfloop index="key" list="#reqList#">
		<cfif not structKeyExists(arguments.xmlData.rss.channel,key)>
			<cfset result[key] = "">
		<cfelse>
			<cfset result[key] = arguments.xmlData.rss.channel[key].XmlText>
		</cfif>		
	</cfloop>

	<!--- optional items --->
	<cfloop index="key" list="#optList#">
		<cfif structKeyExists(arguments.xmlData.rss.channel,key)>
			<cfif key is "image">
				<!--- image is a complex struct, just copy via children --->
				<cfloop index="i" from="1" to="#arrayLen(arguments.xmlData.rss.channel[key].XmlChildren)#">
					<cfset result[key][arguments.xmlData.rss.channel[key].XmlChildren[i].XmlName] = arguments.xmlData.rss.channel[key].XmlChildren[i].XmlText>
				</cfloop>
			<cfelse>
				<cfset result[key] = arguments.xmlData.rss.channel[key].XmlText>
			</cfif>
		</cfif>		
	</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getRSSMetaRss1" access="private" returnType="struct" output="true"
			hint="Gets meta info for RSS 1 feeds.">
	<cfargument name="xmlData" type="any" required="true" hint="XML object.">
	<cfset var result = structNew()>
	<cfset var reqList = "title,link,description">
	<cfset var optList = "image,textinput">
	<cfset var key = "">

	<!--- required items --->
	<cfloop index="key" list="#reqList#">
		<cfif not structKeyExists(arguments.xmlData["rdf:RDF"].channel,key)>
			<cfset result[key] = "">
		<cfelse>
			<cfset result[key] = arguments.xmlData["rdf:RDF"].channel[key].XmlText>
		</cfif>		
	</cfloop>

	<!--- optional items --->
	<cfloop index="key" list="#optList#">
		<cfif structKeyExists(arguments.xmlData["rdf:RDF"].channel,key)>
			<cfset result[key] = arguments.xmlData["rdf:RDF"].channel[key].XmlText>
		</cfif>		
	</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getRSSMetaRss2" access="private" returnType="struct" output="true"
			hint="Gets meta info for RSS 2 feeds.">
	<cfargument name="xmlData" type="any" required="true" hint="XML object.">
	<cfset var result = structNew()>
	<cfset var reqList = "title,link,description">
	<cfset var optList = "language,copyright,managingEditor,webMaster,pubDate,lastBuildDate,category,generator,docs,cloud,ttl,image,rating,textInput,skipHours,skipDays">
	<cfset var key = "">
		
	<!--- required items --->
	<cfloop index="key" list="#reqList#">
		<cfif not structKeyExists(arguments.xmlData.rss.channel,key)>
			<cfset result[key] = "">
		<cfelse>
			<cfset result[key] = arguments.xmlData.rss.channel[key].XmlText>
		</cfif>		
	</cfloop>

	<!--- optional items --->
	<cfloop index="key" list="#optList#">
		<cfif structKeyExists(arguments.xmlData.rss.channel,key)>
			<cfset result[key] = arguments.xmlData.rss.channel[key].XmlText>
		</cfif>		
	</cfloop>

	<cfreturn result>
</cffunction>

<cffunction name="getRSSType" access="public" returnType="struct" output="true"
			hint="Determines the RSS feed type.">
	<cfargument name="xmlData" type="any" required="true" hint="XML Ob, XML String, or URL">
	<cfset var result = structNew()>
	
	<cfset arguments.xmlData = getXML(arguments.xmlData)>
	
	<cfset result.type = "Unknown">
	<cfset result.version = "">

	<!--- RSS 0.91, 0.92, 2.0 --->
	<cfif structKeyExists(arguments.xmlData,"rss") and
		  structKeyExists(arguments.xmlData.rss.xmlAttributes,"version")
		  and listFind("0.91,0.92,2.0",arguments.xmlData.rss.xmlAttributes.version)>
		  <cfset result.type = "RSS">
		  <cfset result.version = arguments.xmlData.rss.xmlAttributes.version>
	</cfif>
	
	<!--- RSS 1.0 --->
	<cfif structKeyExists(arguments.xmlData,"rdf:RDF") and
		  arguments.xmlData["rdf:RDF"].xmlAttributes.xmlns is "http://purl.org/rss/1.0/">
		  <cfset result.type = "RSS">
		  <cfset result.version = "1.0">
	</cfif>

	<!--- Atom X --->
	<cfif structKeyExists(arguments.xmlData,"feed")>
		<!--- For Atom, we insist on version but don't care what it is --->
		<cfif structKeyExists(arguments.xmlData.feed.xmlAttributes,"xmlns") and (arguments.xmlData.feed.xmlAttributes.xmlns is "http://www.w3.org/2005/Atom" or arguments.xmlData.feed.xmlAttributes.xmlns is "http://purl.org/atom/ns##")>
			  <cfset result.type = "Atom">
			  <cfset result.version = "1.0">
		</cfif>
	</cfif>
		
	<cfreturn result>	
</cffunction>

<!--- UTILITY FUNCTIONS --->
<cffunction name="getEmbeddedHTML" access="private" returnType="string" output="true"
			hint="Used to get a string from an html embedded xml packet.">
	<cfargument name="data" type="array" required="true">
	<cfset var str = "">
	<cfset var i = "">

	<cfloop index="i" from="1" to="#arrayLen(arguments.data)#">
		<cfset str = str & arguments.data[i].toString()>
	</cfloop>
	
	<cfreturn str>
</cffunction>


<cffunction name="getXML" access="private" returnType="any" output="true"
			hint="Allows you to pass an XML ob, XML string, or URL and get an XML object back.">
	<cfargument name="data" type="any" required="true">
	
	<cfif isXMLDoc(arguments.data)>
		<cfreturn arguments.data>
	</cfif>
		
	<cfif isURL(arguments.data)>
		<cftry>
			<cfhttp url="#arguments.data#" useragent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.2) Gecko/20060308 Firefox/1.5.0.2">
			<cfset arguments.data = cfhttp.fileContent>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
	
	<cftry>
		<cfif isSimpleValue(trim(arguments.data))>
			<cfreturn xmlParse(arguments.data)>
		</cfif>
		<cfcatch><cfoutput>#htmlCodeFormat(arguments.data)#</cfoutput><cfdump var="#cfcatch#"><cfdump var="#cgi#"><cfabort></cfcatch>
	</cftry>
	
	<cfthrow type="rss.cfc" message="The data passed was not a valid XML object, string, or URL pointing to XML.">
</cffunction>
			
<cffunction name="isURL" access="private" returnType="boolean" output="false"
			hint="Checks to see if a string is a URL. Written by Nathan Dintenfass."> 
	<cfargument name="str" type="string" required="true">
	
	<cfreturn reFindNoCase("^(((https?:|ftp:|gopher:)\/\/))[-[:alnum:]\?%,\.\/&##!@:=\+~_]+[A-Za-z0-9\/]$",arguments.str) NEQ 0>
</cffunction>
			
<cffunction name="renderMeta" access="private" returnType="string" output="true"
			hint="Recursively output a struct in XML format.">
	<cfargument name="data" type="struct" required="true">
	<cfset var s = "">
	<cfset var k = "">
		
	<cfloop item="k" collection="#arguments.data#">
		<cfif isSimpleValue(arguments.data[k])>
			<cfset s = s & "<#lcase(k)#>#arguments.data[k]#</#lcase(k)#>">
		<cfelseif isStruct(arguments.data[k])>
			<cfset s = s & "<#lcase(k)#>" & renderMeta(arguments.data[k]) & "</#lcase(k)#>">
		</cfif>
	</cfloop>
		
	<cfreturn s>
	
</cffunction>			

</cfcomponent>
