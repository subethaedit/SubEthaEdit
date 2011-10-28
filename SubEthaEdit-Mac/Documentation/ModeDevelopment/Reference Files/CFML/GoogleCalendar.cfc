<!---
	Name         : GoogleCalendar.cfc
	Author       : Raymond Camden 
	Created      : 04/20/2006
	Last Updated : 11/11/2010
	History      : Fixed date logic, added ability to return future events only (rkc 9/26/06)
				 : Todd@CFSilence added logic to return reminder info. Date is in minutes (todd 9/27/06)
				 : Scott M. noted that convertDate needed to check for + as well as - (rkc 10/8/06)
				 : added getCalendars, updated addEvent (rkc 10/8/06)
				 : Update to check for multi-day events (rkc 1/4/07)
				 : Fixed an offset issue in start/end time (rkc 8/8/07)
				 : Major rewrite (rkc 8/6/08)
				 : Query updates for getEntries (rkc 8/20/08)
				 : See readme, tired of updating two places... ;)
				 
TODO:
Add sets for tzoffset, calendarurl
--->
<cfcomponent displayName="Google Calendar" hint="Interacts with the Google Calendar API" extends="base" output="false">

<cfset variables.tzOffset = 0>
<cfset variables.username = "">

<!--- EVENT STATUS (Static) --->
<!--- http://code.google.com/apis/gdata/common-elements.html#gdEventStatus --->
<cfset variables.eventStatuses = structNew()>
<cfset variables.eventStatuses["cancelled"] = "http://schemas.google.com/g/2005##event.canceled">
<cfset variables.eventStatuses["confirmed"] = "http://schemas.google.com/g/2005##event.confirmed">
<cfset variables.eventStatuses["tentative"] = "http://schemas.google.com/g/2005##event.tentative">

<!--- TRANSPARENCY STATUS (Static) --->
<cfset variables.busyStatuses["busy"] = "http://schemas.google.com/g/2005##event.opaque">
<cfset variables.busyStatuses["free"] = "http://schemas.google.com/g/2005##event.transparent">

<cffunction name="init" access="public" returnType="GoogleCalendar" output="false">
  <cfargument name="username" type="string" required="true" hint="Username">
  <cfargument name="password" type="string" required="true" hint="Password">
  <cfargument name="tzOffset" type="numeric" required="false" hint="Your offset from GMT.">

  <!--- set up base defaults --->
  <cfset super.init(arguments.tzoffset)>
  <cfset getAuthCode(arguments.username,arguments.password,"camden-googlecal-1.0","cl")>
  <cfset variables.username = arguments.username>
  <cfreturn this>
</cffunction>

<cffunction name="addEvent" access="public" returnType="any" output="false" hint="Adds an event. Returns Success or another message.">
  <cfargument name="title" type="string" required="true">
  <cfargument name="description" type="string" required="true">
  <cfargument name="start" type="date" required="true">
  <cfargument name="end" type="date" required="true">
  <cfargument name="where" type="string" required="false">
  <cfargument name="authorname" type="string" required="false">
  <cfargument name="authoremail" type="string" required="false">
  <cfargument name="busy" type="boolean" required="false">
  <cfargument name="eventstatus" type="string" required="false">
  <cfargument name="calendarid" type="string" required="false">
  <cfargument name="allday" type="boolean" required="false">
  <cfargument name="resultType" type="string" required="false" hint="fileContent,fullResponse,successCode" default="successcode">
  <cfargument name="recurrence" type="struct" required="false" hint="struct with all recurrence info you need these values in your struct... dow, dom, interval, frequency, until, byday">

  <cfset var busyCode = "">
  <cfset var eventCode = "">
  <cfset var result = "">
  <cfset var myxml = "">
  <cfset var loc = "">
  <cfset var curl = "http://www.google.com/calendar/feeds/default/private/full">
  <cfset var recur = "">
  
  <cfset var masterStart = start>
  <cfset var masterEnd = "">


  <cfif structKeyExists(arguments, "allDay") and allDay>
  	<cfset masterEnd = start>
    <cfelse>
    <cfset masterEnd = end>
  </cfif>
  
  <cfif structKeyExists(arguments, "calendarid")>
    <!--- manipulate the curl --->
    <cfset curl = replace(curl, "/default", "/#arguments.calendarid#")>
  </cfif>

  <!--- if all day event no need for times --->
  <cfif structKeyExists(arguments, "allday") AND arguments.allday>
    <cfset arguments.start = dateFormat(arguments.start, "yyyy-mm-dd")>
    <cfset arguments.end = dateFormat(arguments.end, "yyyy-mm-dd")>
  <cfelse>
    <!--- add our offsets to our times --->
    <cfset arguments.start = dateAdd("h", -1 * getTZOffset(), arguments.start)>
    <cfset arguments.end = dateAdd("h", -1 * getTZOffset(), arguments.end)>
    <!--- Nice logic by Roger Benningfield --->
    <cfset arguments.start = dateFormat(arguments.start, "yyyy-mm-dd") & "T" & timeFormat(arguments.start, "HH:mm:ss") & "Z">
    <cfset arguments.end = dateFormat(dateadd('d',1,arguments.end), "yyyy-mm-dd") & "T" & timeFormat(arguments.end, "HH:mm:ss") & "Z">
  </cfif>

  <!--- convert busy/eventstatus --->

  <cfif structKeyExists(arguments, "busy")>

    <cfif arguments.busy>

      <cfset busyCode = getBusyStatusCode("busy")>
 
    <cfelse>
 
      <cfset busyCode = getBusyStatusCode("free")>
 
    </cfif>
 
  </cfif>
 
  <cftry>
    <cfsavecontent variable="myxml">
    <cfoutput>
      <entry xmlns='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'>
        <category scheme='http://schemas.google.com/g/2005##kind' term='http://schemas.google.com/g/2005##event'></category>
        <title type='text'>#arguments.title#</title>
        <content type='html'>#xmlFormat(arguments.description)#</content>
    <cfif structKeyExists(arguments, "authorname") and structKeyExists(arguments, "authoremail")>
          <author>
            <name>#arguments.authorName#</name>
            <email>#arguments.authorEmail#</email>
          </author>
    </cfif>
 
    <cfif busyCode is not "">
          <gd:transparency value='http://schemas.google.com/g/2005##event.opaque'> </gd:transparency>
    </cfif>
 
    <cfif eventCode is not "">
          <gd:eventStatus value='http://schemas.google.com/g/2005##event.confirmed'> </gd:eventStatus>
    </cfif>
 
        <!--- if the structure is defined then its recurrence time!--->
    <cfif isDefined('recurrence')>

        <cfset recur = createRecurrenceString(recurrence,allday,masterStart,masterEnd)>
        <gd:recurrence xmlns:gd="http://schemas.google.com/g/2005"> #recur# </gd:recurrence>

    <cfelse>
          <!--- no recurrence so set the start and end date/times--->
      <cfif structKeyExists(arguments, "where")>
            <gd:where valueString='#arguments.where#'></gd:where>
      </cfif>
          <gd:when startTime='#arguments.start#' endTime='#arguments.end#'></gd:when>
    </cfif>
      </entry>
    </cfoutput>
    </cfsavecontent>

    <cfcatch>
		<cfrethrow>
    </cfcatch>

  </cftry>

  <cfhttp url="#curl#" method="post" result="result" redirect="false">
    <cfhttpparam type="header" name="Content-Type" value="application/atom+xml">
    <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
    <cfhttpparam type="body" value="#myxml#">
  </cfhttp>

  <cfif result.responseheader.status_code is "302">

    <cfset loc = result.responseheader.location>

    <cfhttp url="#loc#" method="post" result="result" redirect="false">
      <cfhttpparam type="header" name="Content-Type" value="application/atom+xml">
      <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
      <cfhttpparam type="body" value="#myxml#">
    </cfhttp>
  
  </cfif>
  
  <cfif result.responseheader.status_code is "201">
    
	<cfif arguments.resultType eq 'fileContent'>
      <cfreturn result.fileContent>
    
	<cfelseIf arguments.resultType eq 'fullResponse'>
      <cfreturn result>
    
    <cfelse>
      <cfreturn "Success">
    </cfif>
    
    <cfelse>
    <cfreturn "Error: #result.statuscode# #result.filecontent#">
  </cfif>
</cffunction>

	<!--- add calendar --->
    <cffunction name="addCalendar" access="public" returnType="string" output="false" hint="Adds a calendar. Returns Success or another message.">
        <cfargument name="title" type="string" required="true">
        <cfargument name="description" type="string" required="true">
        <cfargument name="color" type="string" required="true" hint="the hex code for a color">
    
        <cfset var busyCode = "">
        <cfset var eventCode = "">
        <cfset var result = "">
        <cfset var myxml = "">
        <cfset var loc = "">
        <cfset var curl = "http://www.google.com/calendar/feeds/default/owncalendars/full">
        
        <cfif structKeyExists(arguments, "calendarid")>
        <!---manipulate the curl --->
            <cfset curl = replace(curl, "/default", "/#arguments.calendarid#")>
        </cfif>
        
        <cfsavecontent variable="myxml">
            <cfoutput>
            <entry xmlns='http://www.w3.org/2005/Atom' 
               xmlns:gd='http://schemas.google.com/g/2005' 
               xmlns:gCal='http://schemas.google.com/gCal/2005'>
            <title type='text'>#arguments.title#</title>
            
            <summary type='text'>#xmlFormat(arguments.description)#</summary>
            <gCal:timezone value='Central'></gCal:timezone>
            <gCal:hidden value='false'></gCal:hidden>
            <gCal:color value='#color#'></gCal:color>
            <gd:where rel='' label='' valueString=''></gd:where>
            </entry>
            </cfoutput>
        </cfsavecontent>
        
        <cfhttp url="#curl#" method="post" result="result" redirect="false">
            <cfhttpparam type="header" name="Content-Type" value="application/atom+xml">
            <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
            <cfhttpparam type="body" value="#myxml#">
        </cfhttp>
        
        <cfif result.responseheader.status_code is "302">
            <cfset loc = result.responseheader.location>
            <cfhttp url="#loc#" method="post" result="result" redirect="false">
                <cfhttpparam type="header" name="Content-Type" value="application/atom+xml">
                <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
                <cfhttpparam type="body" value="#myxml#">
            </cfhttp>
        </cfif>
        
        <cfif result.responseheader.status_code is "201">
            <cfreturn "Success">
        
        <cfelse>
            <cfreturn "Error: #result.statuscode# #result.filecontent#">
        </cfif>
    </cffunction>
    
    <cffunction name="deleteEvent" access="public" returnType="string" hint="Deletes an event." output="false">
        <cfargument name="id" type="string" required="true" hint="ID value of entry.">
        <cfset var result = "">
        
        <cfhttp url="#urlDecode(arguments.id)#" method="DELETE" result="result" redirect="true">
            <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authCode#">
            <cfhttpparam type="header" name="If-Match" value="*">
        </cfhttp>
        
        <cfif structKeyExists(result.responseheader,"location")>
            <cfhttp url="#result.responseheader.location#" method="DELETE" result="result" redirect="true">
                <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authCode#">
                <cfhttpparam type="header" name="If-Match" value="*">
            </cfhttp>
        </cfif>
        
        <cfif result.responseheader.status_code is "201">
        	<cfreturn "Success">
        <cfelse>
        	<cfreturn "Error: #result.statuscode#">
        </cfif>
    </cffunction>
  
    <cffunction name="getBusyStatuses" access="private" returnType="struct" output="false" hint="Returns structure of Busy Statuses">
    	<cfreturn variables.busyStatuses>
    </cffunction>
    
    <cffunction name="getBusyStatusCode" access="private" returnType="string" output="false" hint="Translates a string to gd:transparency.">
        <cfargument name="string" type="string" required="true">
        
		<cfset var es = getBusyStatuses()>
        
		<cfif structKeyExists(es, arguments.string)>
        	<cfreturn es[arguments.string]>
        </cfif>
        
        <cfthrow message="Invalid string passed to getBusyStatusCode: #arguments.string#">
    </cffunction>
  
    <cffunction name="getBusyStatusString" access="private" returnType="string" output="false" hint="Translates a gd:transparency to a string.">
        <cfargument name="code" type="string" required="true">
        
		<cfset var es = getBusyStatuses()>
        <cfset var key = "">
        
        <cfloop item="key" collection="#es#">
        	<cfif es[key] is arguments.code>
        		<cfreturn key>
        	</cfif>
        </cfloop>
        
        <cfthrow message="Invalid code passed to getBusyStatusString: #arguments.code#">
    </cffunction>

    <cffunction name="getCalendars" access="public" returnType="query" output="false" hint="Returns all the calendars for the user.">
    
		<cfset var getcalurl = "http://www.google.com/calendar/feeds/default">
        <cfset var result = "">
        <cfset var cals = queryNew("accesslevel,color,hidden,id,published,summary,timezone,title,updated,where")>
        <cfset var calListXML = "">
        <cfset var x = "">
        <cfset var numCals = "">
        <cfset var entry = "">
        <cfset var cal = "">
        <cfset var lpos = "">
        <cfset var key = "">
        
        <cfhttp url="#getcalurl#" method="get" result="result">
        	<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
        </cfhttp>
        
		<cfif result.responseheader.status_code is "200">
        	<cfset calListXML = xmlParse(result.filecontent)>
        	<cfset numCals = arrayLen(calListXML.feed.entry)>
        	<cfloop index="x" from="1" to="#numCals#">
        		<cfset entry = calListXML.feed.entry[x]>
        		<cfset cal = structNew()>
        		<cfset cal.id = listLast(entry.id.xmlText,"/")>
        		<cfset cal.published = convertDate(entry.published.xmltext, variables.tzoffset)>
        		<cfset cal.updated = convertDate(entry.updated.xmltext, variables.tzoffset)>
        		<cfset cal.title = entry.title.xmltext>
        		
				<cfif structKeyExists(entry, "summary")>
        			<cfset cal.summary = entry.summary.xmltext>
        		
                <cfelse>
        			<cfset cal.summary = "">
        		</cfif>
        		
				<cfset cal.timezone = entry["gCal:timezone"].xmlAttributes.value>
        		<cfset cal.hidden = entry["gCal:hidden"].xmlAttributes.value>
        		<cfset cal.color = entry["gCal:color"].xmlAttributes.value>
        		<cfset cal.accesslevel = entry["gCal:accesslevel"].xmlAttributes.value>
				
				<cfif structKeyExists(entry, "gCal:where")>
                	<cfset cal.where = entry["gCal:where"].xmlAttributes.valueString>
                <cfelse>
                	<cfset cal.where = "">
                </cfif>
                
				<cfset queryAddRow(cals)>
    
                <cfloop item="key" collection="#cal#">
	                <cfset querySetCell(cals, key, cal[key])>
                </cfloop>
    
        	</cfloop>
        </cfif>
        
        <cfreturn cals>
    </cffunction>

<cffunction name="getEvents" access="public" returnType="any" output="false" hint="Gets events.">
    <cfargument name="calid" type="string" required="true" hint="Calendar ID">
    <cfargument name="returnType" required="false" hint="specify which type of result set is returned (options: query, xmlarray)">
    <cfargument name="maxevents" type="numeric" required="false" hint="Max number of events. Google will default to 25">
    <cfargument name="futureevents" type="boolean" required="false" hint="Show only future events">
    <cfargument name="orderby" type="string" required="false" hint="Can be lastmodified (default) or starttime">
    <cfargument name="sortdir" type="string" required="false" hint="ascending or descending">
    <cfargument name="startMin" type="date" required="false" hint="Earliest date to return.">
    <cfargument name="startMax" type="date" required="false" hint="Latest date to return.">
    <cfargument name="singleEvents" type="string" required="false" hint="Expand Recurring events.">
    <cfargument name="q" type="string" required="false" hint="Simple keyword for search.">
        
	<cfset var result = "">
    <cfset var baseurl = "http://www.google.com/calendar/feeds">
    <cfset var entries = "">
    <cfset var s = "">
    <cfset var x = "">
    <cfset var col = "">
    <cfset var key = "">
    <cfset var y = "">
    <cfset var events = queryNew("author,authoremail,busystatus,date,endtime,eventstatus,recurrence,reminder,starttime,where,category,content,id,published,title,updated,editlink,who")>
    <cfset var entry = "">
    <cfset var theOffset = "">
    <cfset var curl = "#baseurl#/#arguments.calid#/private/full?">
    <cfset var recData = "">
    
    <cfset arguments.calid = trim(arguments.calid)>
    
	<cfif structKeyExists(arguments, "maxevents")>
    	<cfset curl = curl & "&max-results=#arguments.maxevents#">
    </cfif>
    
	<cfif structKeyExists(arguments, "futureevents")>
    	<cfset curl = curl & "&futureevents=#arguments.futureevents#">
    </cfif>
    
	<cfif structKeyExists(arguments, "orderby")>
    	<cfset curl = curl & "&orderby=#arguments.orderby#">
    </cfif>
    
	<cfif structKeyExists(arguments, "sortdir")>
    	<cfset curl = curl & "&sortorder=#arguments.sortdir#">
    </cfif>
    
	<cfif structKeyExists(arguments, "startMin")>
    	<cfset curl = curl & "&start-min=#DateFormat(arguments.startMin, "yyyy-mm-dd")#T00:00:00">
    </cfif>
    
	<cfif structKeyExists(arguments, "startMax")>
    	<cfset curl = curl & "&start-max=#DateFormat(arguments.startMax, "yyyy-mm-dd")#T23:59:59">
    </cfif>
    
	<cfif structKeyExists(arguments, "q")>
    	<cfset curl = curl & "&q=#urlEncodedFormat(arguments.q)#">
    </cfif>
    
	<cfif structKeyExists(arguments, "singleevents")>
    	<cfset curl = curl & "&singleevents=#arguments.singleEvents#">
    </cfif>
    
    <cfhttp url="#curl#" result="result">
    	<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
    </cfhttp>
       
	<cfset entries = xmlSearch(result.fileContent,"//*[local-name() = 'entry']")>
    <cfloop index="x" from="1" to="#arrayLen(entries)#">
    	
		<cfset entry = entries[x]>
    	<cfset s = structNew()>
    	
        <cfloop index="col" list="id,published,updated,title,content,category">
    		<cfset s[col] = entry[col].xmlText>
    	</cfloop>
    	
		<cfset s.author = "">
    	
		<cfif structKeyExists(entry, "author") and structKeyExists(entry.author, "name")>
    		<cfset s.author = entry.author.name.xmlText>
    	</cfif>
    	
		<cfset s.authoremail = "">
    	
		<cfif structKeyExists(entry, "author") and structKeyExists(entry.author, "email")>
    		<cfset s.authoremail = entry.author.email.xmlText>
    	</cfif>
    	
		<cfset s.where = "">
    	
		<cfif structKeyExists(entry, "gd:where") and structKeyExists(entry["gd:where"].xmlAttributes,"valueString")>
    		<cfset s.where = entry["gd:where"].xmlAttributes.valueString>
    	</cfif>
    
		<cfset s.busystatus = "">
    
    	<cfif structKeyExists(entry, "gd:transparency") and structKeyExists(entry["gd:transparency"].xmlAttributes,"value")>
    		<cfset s.busystatus = getBusyStatusString(entry["gd:transparency"].xmlAttributes.value)>
    	</cfif>
    
		<cfset s.eventstatus = "">
    	<cfif structKeyExists(entry, "gd:eventstatus") and structKeyExists(entry["gd:eventstatus"].xmlAttributes,"value")>
    		<cfset s.eventstatus = getEventStatusString(entry["gd:eventstatus"].xmlAttributes.value)>
    	</cfif>
    
		<cfif structKeyExists(entry, "gd:recurrence")>
    		<cfset s.recurrence = parseRecurrence(entry["gd:recurrence"].xmlText)>
    
    	<cfelse>
    		<cfset s.recurrence = "Onetime">
    	</cfif>
    
    	<cfset s.starttime = "">
    	<cfset s.endtime = "">
    
    	<cfif structKeyExists(entry, "gd:when") and structKeyExists(entry["gd:when"].xmlAttributes,"starttime")>
    		<cfset s.starttime = entry["gd:when"].xmlAttributes.starttime>
    	</cfif>
    	
		<cfif structKeyExists(entry, "gd:when") and structKeyExists(entry["gd:when"].xmlAttributes,"endtime")>
    		<cfset s.endtime = entry["gd:when"].xmlAttributes.endtime>
    	</cfif>
    
	<!--- This logic written by Todd (todd@cfsilence.com) --->
    	<cfset s.reminder = "">
    	
		<cfif structKeyExists(entry, "gd:when") and structKeyExists(entry["gd:when"], "gd:reminder") and structKeyExists(entry["gd:when"]["gd:reminder"].xmlAttributes,"minutes")>
    		<cfset s.reminder = entry["gd:when"]["gd:reminder"].xmlAttributes.minutes>
    	</cfif>
    
		<cfif structKeyExists(entry, "gd:who")>
    		<cfset s.who = "">
            
            <cfloop index="y" from="1" to="#arrayLen(entry['gd:who'])#">
                
				<cfif NOT findNoCase("group.calendar.google.com",entry["gd:who"][y].xmlAttributes.email)>
                    <cfset s.who = listAppend(s.who,entry["gd:who"][y].xmlAttributes.email)>
                </cfif>
                
            </cfloop>
            
    	</cfif>
    <!--- 
    Funny logic. So it seems as if Google does NOT offset for 'full day' events.
    So a timed event is correct off, but a non timed event is not.
    --->
		<cfif s.starttime is "" or not findNoCase("t", s.starttime)>
            
            <cfif s.recurrence neq "Onetime">
                <cfset recData = parseRecurrenceDate(entry["gd:recurrence"].xmlText)>
            
                <cfif structKeyExists(recData, "startdate")>
                    <cfset s.date = recData.startdate>
                </cfif>
            
                <cfif structKeyExists(recData, "starttime")>
                    <cfset s.starttime = recData.starttime>
                </cfif>
            
                <cfif structKeyExists(recData, "endtime")>
                    <cfset s.endtime = recData.endtime>
                </cfif>
            
            <cfelse>
                <cfset s.date = "">
            </cfif>
        <cfelse>
            <cfset s.date = convertDate(s.starttime, getTZOffset())>
        <!--- 
        offset for startime needs to modded. It has an offset in it.
        So it may be -7. 
        If your offset is -5, then the real offset is +2, or yourOffet-theoffset
        --->
            <cfset theOffset = listLast(s.starttime, "-+")>
            <cfset theOffset = val(listFirst(theOffset,":"))>
        
            <cfif not find("+", s.starttime)>
                <cfset theOffset = -1*theOffset>
            </cfif>
            <cfset s.starttime = convertDate(s.starttime, getTZOffset() )>
        <!--- is it possible endtime doesn't exist? mabe --->
            <cfif s.endtime is not "">
                <cfset theOffset = listLast(s.endtime, "-+")>
                <cfset theOffset = val(listFirst(theOffset,":"))>
                
                <cfif not find("+", s.endtime)>
                    <cfset theOffset = -1*theOffset>
                </cfif>
                <cfset s.endtime = convertDate(s.endtime, getTZOffset())>
            </cfif>
        </cfif>
        
        <cfloop index="y" from="1" to="#arrayLen(entry.link)#">
        
            <cfif entry.link[y].xmlAttributes.rel is "edit">
                <cfset s.editlink = entry.link[y].xmlAttributes.href>
            </cfif>
        
        </cfloop>
        
        <cfset queryAddRow(events)>
        
        <cfloop item="key" collection="#s#">
            <cfset querySetCell(events, key, s[key])>
        </cfloop>
        
    </cfloop>
    
	<cfif isDefined('arguments.returnType')>
    
		<cfif arguments.returnType eq 'xmlarray'>
            <cfreturn entries>
        <cfelseif arguments.returnType eq 'query'>
            <cfreturn events>
        <cfelse>
            <cfreturn events>
        </cfif>
    <cfelse>
    	<cfreturn events>
    </cfif>
</cffunction>

    <cffunction name="getEventStatuses" access="private" returnType="struct" output="false" hint="Returns structure of Event Statuses">
    	<cfreturn variables.eventStatuses>
    </cffunction>
    
    <cffunction name="getEventStatusCode" access="private" returnType="string" output="false" hint="Translates a string to gd:eventstatus.">
        <cfargument name="string" type="string" required="true">
        
		<cfset var es = getEventStatuses()>
        
		<cfif structKeyExists(es, arguments.string)>
        	<cfreturn es[arguments.string]>
        </cfif>
        
        <cfthrow message="Invalid string passed to getEventStatusCode: #arguments.string#">
    </cffunction>
    
    <cffunction name="getEventStatusString" access="private" returnType="string" output="false" hint="Translates a gd:eventStatus to a string.">
        <cfargument name="code" type="string" required="true">

        <cfset var es = getEventStatuses()>
        <cfset var key = "">

        <cfloop item="key" collection="#es#">
	        <cfif es[key] is arguments.code>
		        <cfreturn key>
    	    </cfif>
        </cfloop>

        <cfthrow message="Invalid code passed to getEventStatusString: #arguments.code#">
    </cffunction>
    
    <cffunction name="getTZOffset" access="public" returnType="numeric" output="false" hint="Returns tzoffset value.">
	    <cfreturn variables.tzOffset>
    </cffunction>
  
    <cffunction name="parseRecurrence" access="private" returnType="string" output="false" hint="Translate the funky recurrence data into a nice string.">
    	<cfargument name="recurrence" type="string" required="true">
    	
		<cfset var result = "">
    	<cfset var freq = "">
    <!--- get freq --->
    	<cfset freq = reFindNoCase("FREQ=[a-z]*", arguments.recurrence,1,true)>
    <!--- Right now my logic is to just use the freq string. Not 100% right. --->
    	<cfif freq.pos[1] neq 0>
    		<cfset freq = mid(arguments.recurrence, freq.pos[1], freq.len[1])>
    		<cfset freq = replaceNoCase(freq, "FREQ=", "")>
    		<cfset result = freq>
    	</cfif>
    	<cfreturn result>
    </cffunction>
  <!--- REALLY unsure about some of the changes here... --->
    <cffunction name="parseRecurrenceDate" access="private" returnType="struct" output="false" hint="Translate the funky recurrence data into a nice string.">
        <cfargument name="recurrence" type="string" required="true">
        
		<cfset var result = structNew()>
        <cfset var resultstr = "">
        <cfset var datestring = "" abs ABS Abs()>
        <cfset var year = "">
        <cfset var month = "">
        <cfset var day = "">
        <cfset var hour = "">
        <cfset var minute = "">
        <cfset var second = "">
        <!--- get freq --->
        <cfset datestring = reFindNoCase("DTSTART;(VALUE=DATE|TZID=[a-z/]+):([0-9]+)(T([0-9]+)){0,1}", arguments.recurrence,1,true)>
        
		<cfif datestring.pos[1] neq 0 and arrayLen(datestring.pos) gte 3>
        	<cfset resultstr = mid(arguments.recurrence, datestring.pos[3], datestring.len[3])>
        <!--- This should be YYYYMMDD --->
        	<cfif len(resultstr) is 8>
        		<cfset year = left(resultstr, 4)>
        		<cfset month = mid(resultstr, 5, 2)>
        		<cfset day = right(resultstr, 2)>
        		<cfset result.startdate = createDate(year,month,day)>
        	</cfif>
        </cfif>
        
		<cfif arrayLen(datestring.pos) gte 4 and datestring.pos[4] neq 0>
        	<cfset resultstr = mid(arguments.recurrence, datestring.pos[4], datestring.len[4])>
        <!--- This should be HHMMSS --->
        	<cfif len(resultstr) is 7>
        <!--- strip the T --->
        		<cfset resultstr = replace(resultstr, "T", "")>
        		<cfset hour = left(resultstr, 2)>
        		<cfset minute = mid(resultstr, 3, 2)>
        		<cfset second = right(resultstr, 2)>
        		<cfset result.starttime = createDateTime(year,month,day,hour,minute,second)>
        <!--- go ahead and set start to the same... --->
        		<cfset result.startdate = result.starttime>
        	</cfif>
        </cfif>
        
		<cfset datestring = reFindNoCase("DTEND;(VALUE=DATE|TZID=[a-z/]+):([0-9]+)(T([0-9]+)){0,1}", arguments.recurrence,1,true)>
        
		<cfif datestring.pos[1] neq 0 and arrayLen(datestring.pos) gte 3>
        	<cfset resultstr = mid(arguments.recurrence, datestring.pos[3], datestring.len[3])>
        <!--- This should be YYYYMMDD --->
        	<cfif len(resultstr) is 8>
        		<cfset year = left(resultstr, 4)>
        		<cfset month = mid(resultstr, 5, 2)>
        		<cfset day = right(resultstr, 2)>
        		<cfset result.enddate = createDate(year,month,day)>
        	</cfif>
        </cfif>
        
		<cfif arrayLen(datestring.pos) gte 4 and datestring.pos[4] neq 0>
        	<cfset resultstr = mid(arguments.recurrence, datestring.pos[4], datestring.len[4])>
        <!--- This should be HHMMSS --->
        	<cfif len(resultstr) is 7>
        		<cfset resultstr = replace(resultstr, "T", "")>
        		<cfset hour = left(resultstr, 2)>
        		<cfset minute = mid(resultstr, 3, 2)>
        		<cfset second = right(resultstr, 2)>
        		<cfset result.endtime = createDateTime(year,month,day,hour,minute,second)>
        	</cfif>
        </cfif>
        
        <cfreturn result>
    </cffunction>  

    <cffunction name="updateEvent" access="remote" returntype="any" output="false" hint="updates an event">
        <cfargument name="calID" required="true">
        <cfargument name="eventID" required="true">
        <cfargument name="title" type="string" required="false">
        <cfargument name="description" type="string" required="false">
        <cfargument name="start" type="date" required="false">
        <cfargument name="end" type="date" required="false">
        <cfargument name="where" type="string" required="false">
        <cfargument name="authorname" type="string" required="false">
        <cfargument name="authoremail" type="string" required="false">
        <cfargument name="busy" type="boolean" required="false">
        <cfargument name="eventstatus" type="string" required="false">
        <cfargument name="allday" type="boolean" required="false">
        <cfargument name="recurrence" type="struct" required="false" >
        <cfargument name="resultType" type="string" hint='fullResponse'>
        <cfargument name="editLink" type="string" hint="custom edit link used for deleting a single occurance in an event series" default="">
		<cfset var events = "">
        <cfset var repStr = "">
    	<cfset var x2 = "">
		<cfset var x3 = "">
        <cfset var recur = "">
        <cfset var editURL = "">
        <cfset var xml = "">
        <cfset var eventInfo = "">
        <cfset var y = "">
		<cfset var masterEnd = "">
		<cfset var x = "">
		<cfset var updateResult = "">
		
        <!---get the events and loop through them to get the events info--->
        <cfinvoke method="getEvents" returnvariable="events">
            <cfinvokeargument name="calID" value="#arguments.calID#">
            <cfinvokeargument name="returnType" value="xmlarray">
            <cfinvokeargument name="maxevents" value="100000">
      	</cfinvoke>
        
        <cfif allday>
        	<cfset masterEnd = start>
        <cfelse>
        	<cfset masterEnd = end>
        </cfif>
        <cfloop index="x" from="1" to="#arrayLen(events)#">
			
			<cfif compare(urldecode(events[x].id.xmltext), urldecode(eventID)) eq 0><!--- if the event id's are the same --->
				<cfset events[x].title.xmlText = arguments.title>
                <cfset events[x].content.xmlText = arguments.description>
                
                <cfif structKeyExists(events[x], "author") and structKeyExists(events[x].author, "name")>
    	            <cfset events[x].author.name.xmlText = arguments.authorName>
	            </cfif>
                
	            <cfif structKeyExists(events[x], "author") and structKeyExists(events[x].author, "email")>
		            <cfset events[x].author.email.xmlText = arguments.authoremail>
	            </cfif>
	            <cfif structKeyExists(events[x], "gd:where") and structKeyExists(events[x]["gd:where"].xmlAttributes,"valueString")>
		            <cfset events[x]["gd:where"].xmlAttributes.valueString = arguments.where>
	            </cfif>
            <!--- handle event date and time --->
	
                <cfif not isdefined('recurrence')><!--- if the recurrence structure is not passed to the functions--->
            <!--- get rid of recurrence stucture if it is there--->
					<cfscript>
                        structDelete(events[x],'gd:recurrence');
                    </cfscript>
        
                    <cfif allDay>
                
                        <!--- needed if going from a recurring structure to a single instance and event is all day--->
                        <cfif not structKeyExists(events[x], "gd:when")>
                        
                            <cfset repStr = '<gd:when xmlns:gd="http://schemas.google.com/g/2005" endTime="#DateFormat(arguments.end,"yyyy-mm-dd")#" startTime="#DateFormat(arguments.start,"yyyy-mm-dd")#"><gd:reminder method="email" minutes="10"/><gd:reminder method="alert" minutes="10"/></gd:when></entry>'>
                            <cfset x2 = rereplace(events[x],"</entry>",repStr,"one")>
                            
                            <cfelse>
                            
                            <cfif structKeyExists(events[x], "gd:when") and structKeyExists(events[x]["gd:when"].xmlAttributes,"starttime") and isDefined('arguments.start')>
                                <cfset events[x]["gd:when"].xmlAttributes.starttime = DateFormat(arguments.start,'yyyy-mm-dd')>
                            </cfif>
                            
                            <cfif structKeyExists(events[x], "gd:when") and structKeyExists(events[x]["gd:when"].xmlAttributes,"endtime") and isDefined('arguments.end')>
                                <cfset events[x]["gd:when"].xmlAttributes.endtime = DateFormat(DateAdd('d',1,arguments.end),'yyyy-mm-dd')><!---DateAdd('d',1,arguments.end),'yyyy-mm-dd')>--->
                            </cfif>
                        
                        </cfif>
                        
                    <cfelse>
                
                        <!--- needed if going from a recurring structure to a single instance and event is not all day--->
                        <cfif not structKeyExists(events[x], "gd:when")>
                        
                        <cfset repStr = '<gd:when xmlns:gd="http://schemas.google.com/g/2005" endTime="#DateFormat(arguments.end,"yyyy-mm-dd")#T#TimeFormat(arguments.end,"HH:mm:ss")#" startTime="#DateFormat(arguments.start,"yyyy-mm-dd")#T#TimeFormat(arguments.start,"HH:mm:ss")#"></gd:when></entry>'>
                        <cfset x2 = rereplace(events[x],"</entry>",repStr,"one")>
                        
                        <cfelse>
                        
                        <cfif structKeyExists(events[x], "gd:when") and structKeyExists(events[x]["gd:when"].xmlAttributes,"starttime") and isDefined('arguments.start')>
                            <cfset events[x]["gd:when"].xmlAttributes.starttime = DateFormat(arguments.start,'yyyy-mm-dd') & 'T' & TimeFormat(arguments.start,'HH:mm:ss')>
                        </cfif>
                        
                        <cfif structKeyExists(events[x], "gd:when") and structKeyExists(events[x]["gd:when"].xmlAttributes,"endtime") and isDefined('arguments.end')>
                            <cfset events[x]["gd:when"].xmlAttributes.endtime = DateFormat(arguments.end,'yyyy-mm-dd') & 'T' & TimeFormat(arguments.end,'HH:mm:ss')>
                        </cfif>
                        
                        </cfif>
                    
                    </cfif>
                
                <!--- make x an xml object again --->
                    <cfif isXML('x2')>
                        <cfset x3 = XMLParse(x2)>
                    <cfelse>
                        <cfset x3 = events[x]>
                    </cfif>
                    
                </cfif>
                <!--- deal with recurrence--->
                
                <cfif isDefined('recurrence')>
                    <cfset recur = createRecurrenceString(recurrence,allday,start,masterEnd)>
                    <cfif not StructKeyExists(events[x], "gd:recurrence")>
                <!--- awful things done here to get the recurrence to work--->
                        <cfset repStr = '<gd:recurrence xmlns:gd="http://schemas.google.com/g/2005">#recur#</gd:recurrence></entry>'>
                        <cfset x2 = rereplace(events[x],"</entry>",repStr,"one")>
                        <cfset x3 = XMLParse(x2)>
                    <cfelse>
                        <cfset events[x]["gd:recurrence"].xmlText = #recur#>
                        <cfset x3 = events[x]>
                    </cfif>
                <cfelse>
                
                </cfif>
                <!--- get edit url to update event with --->
                <cfloop index="y" from="1" to="#arrayLen(events[x].link)#">
                    <cfif events[x].link[y].xmlAttributes.rel is "edit">
                        <cfset editURL = events[x].link[y].xmlAttributes.href>
                    </cfif>
                </cfloop>
                
                <cfif editLink neq ''>
                    <cfset editURL = editLink>
                </cfif>
                
                <cfset xml = x3>
                
                <cfinvoke method="sendUpdateEventRequest" returnvariable="updateResult">
                    <cfinvokeargument name="editURL" value="#editURL#">
                    <cfinvokeargument name="xml" value="#xml#">
                </cfinvoke>
                
                <cfset eventInfo = structNew()>
                
                <cfif resultType eq 'fullResponse'>
                    <cfreturn updateResult>
                <!---<cfelse>
                    <cfreturn "Error: #result.statuscode# #result.filecontent#">--->
                </cfif>
            </cfif>
        </cfloop>
        <cfreturn 'Could not find event to update'>
    </cffunction>

  
    <cffunction name="createRecurrenceString" access="remote" returntype="any" hint="creates a recurrence string for adding or updating an event" output="false">
        <cfargument name="recurrence" required="true">
        <cfargument name="allday" required="true">
        <cfargument name="start" required="true">
        <cfargument name="end" required="true">
		<cfset var recur = "">

		<cfif allday>
        
            <cfset recur = "DTSTART;VALUE=DATE:#DateFormat(arguments.start,'yyyymmdd')#
DTEND;VALUE=DATE:#DateFormat(arguments.end,'yyyymmdd')#
">

		<cfelse>

			<cfset recur = "DTSTART;TZID=America/Chicago:#DateFormat(arguments.start,'yyyymmdd')#T#TimeFormat(arguments.start,'HHmmss')#
DTEND;TZID=America/Chicago:#DateFormat(arguments.end,'yyyymmdd')#T#TimeFormat(arguments.end,'HHmmss')#
">

		</cfif>

		<cfset recur = recur & "RRULE:FREQ=#recurrence.frequency#;WKST=SU;">
		<cfif not allDay>
        <!--- You will noticed that there are four hours added on to the following line. this is done because it is what google does to get the recurrence to run correctly. Dont ask... --->
        	<cfset recur = recur & "UNTIL=#DateFormat(recurrence.until,'yyyymmdd')#T#TimeFormat(dateadd('h',4,recurrence.until),'HHmmss')#Z;">
        <cfelse>
        	<cfset recur = recur & "UNTIL=#DateFormat(recurrence.until,'yyyymmdd')#;">
		</cfif>
        <cfset recur = recur & "INTERVAL=#recurrence.interval#;">
		<cfif recurrence.monthday>
			<cfset recur = recur & "BYMONTHDAY=#recurrence.DOM#
">

		<cfelse>

			<cfset recur = recur & "BYDAY=#recurrence.byday#
">

		</cfif>

		<cfset recur = recur & "BEGIN:VTIMEZONE
TZID:America/Chicago
X-LIC-LOCATION:America/Chicago
BEGIN:DAYLIGHT
TZOFFSETFROM:-0600
TZOFFSETTO:-0500
TZNAME:CDT
DTSTART:19700308T020000
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:-0500
TZOFFSETTO:-0600
TZNAME:CST
DTSTART:19701101T020000
RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
END:STANDARD
END:VTIMEZONE
">
        <cfreturn recur>
    </cffunction>
    
    <cffunction name="removeAllEvents" access="remote" output="yes">
        <cfargument name="calID" required="true">
   		<cfset var events = "">
        <cfset var test = "">
		<cfset var editURL = "">
		<cfset var x = "">
		<cfset var y = "">
		
        <cfinvoke method="getEvents" returnvariable="events">
            <cfinvokeargument name="calID" value="#arguments.calID#">
            <cfinvokeargument name="returnType" value="xmlarray">
            <cfinvokeargument name="singleEvents" value="false">
            <cfinvokeargument name="maxevents" value="10000">
      	</cfinvoke>
    	
        <cfloop index="x" from="1" to="#arrayLen(events)#">
			<cftry>      		
                <cfloop index="y" from="1" to="#arrayLen(events[x].link)#">
                    <cfif events[x].link[y].xmlAttributes.rel is "edit">
                        <cfset editURL = events[x].link[y].xmlAttributes.href>
                    </cfif>
                </cfloop>
                   
                <cfif structKeyExists(events[x], "gd:eventStatus")>
                    <cfset events[x]["gd:eventStatus"].xmlattributes.value = 'http://schemas.google.com/g/2005##event.canceled'>
                </cfif>
                    
                <cfset test = sendUpdateEventRequest(editURL,events[x])>
                
                <cfcatch>
                    <cfoutput>ERROR - #cfcatch.Message#</cfoutput><br>
                </cfcatch>
            </cftry>
            
        </cfloop>    
    </cffunction>
    
	<cffunction name="removeSingleOccurance" access="remote" output="false">
    	<cfargument name="eventTitle" required="true">
        <cfargument name="date" type="date" required="true">
        <cfargument name="calID" required="true">
		<cfset var editURL = "">
		<cfset var test = "">
		<cfset var x = "">
		<cfset var y = "">
		<cfset var events = "">
     
        <cfinvoke method="getEvents" returnvariable="events">
            <cfinvokeargument name="calID" value="#calID#">
            <cfinvokeargument name="returnType" value="xmlarray">
            <cfinvokeargument name="singleEvents" value="true">
            <cfinvokeargument name="maxevents" value="100000">
            <cfinvokeargument name="q" value="#eventTitle#">
        </cfinvoke>

         <cfloop index="x" from="1" to="#arrayLen(events)#">			
            <cftry>
      		
			<cfif compare(urldecode(events[x].title.xmltext), eventTitle) eq 0 and dateCompare(ParseDateTime(date), ParseDateTime(mid(replace(events[x]["gd:when"].xmlAttributes.startTime, "T", " "),1, 19)),'d') eq 0>

                <cfloop index="y" from="1" to="#arrayLen(events[x].link)#">

					<cfif events[x].link[y].xmlAttributes.rel is "edit">
                        <cfset editURL = events[x].link[y].xmlAttributes.href>
                    </cfif>
                
                </cfloop>
               
				<cfif structKeyExists(events[x], "gd:eventStatus")>
                	<cfset events[x]["gd:eventStatus"].xmlattributes.value = 'http://schemas.google.com/g/2005##event.canceled'>
              	</cfif>
                
				<cfset test = sendUpdateEventRequest(editURL,events[x])>
                <cfreturn test>    
			
            </cfif>
			
            <cfcatch>
            	<cfoutput>ERROR - #cfcatch.Message#</cfoutput><br>
            </cfcatch>
            </cftry>
            
        </cfloop>     
        
    </cffunction>
	
    <cffunction name="sendUpdateEventRequest" access="remote" returntype="any" description="send HTTP request to google for an update of an event" output="false">
    	<cfargument name="editURL" required="true">
    	<cfargument name="xml" required="true">
    	<cfset var loc = "">
		<cfset var result = "">
		
        <cfhttp url="#editURL#" method="put" result="result" redirect="false">
            <cfhttpparam type="header" name="Content-Type" value="application/atom+xml">
            <cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
            <cfhttpparam type="body" value="#xml#">
        </cfhttp>
        
		<cfif result.responseheader.status_code is "302">
        	<cfset loc = result.responseheader.location>
        	
            <cfhttp url="#loc#" method="put" result="result" redirect="false">
        		<cfhttpparam type="header" name="Content-Type" value="application/atom+xml">
        		<cfhttpparam type="header" name="Authorization" value="GoogleLogin auth=#variables.authcode#">
        		<cfhttpparam type="body" value="#xml#">
        	</cfhttp>
        
        </cfif>
        
        <cfreturn result>
    </cffunction>
  </cfcomponent>
