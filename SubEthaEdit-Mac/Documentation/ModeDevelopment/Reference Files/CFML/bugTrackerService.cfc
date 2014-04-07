<cfcomponent>
	<cfset variables.bugEmailSender = "">
	<cfset variables.bugEmailRecipients = "">
	<cfset variables.defaultSeverityCode = "ERROR">
	
	<cfset variables.hostName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName()>
	<cfset variables.appName = replace(application.applicationName," ","","all")>
	
	<cffunction name="init" returntype="bugTrackerService" access="public" hint="Constructor">
		<cfargument name="bugEmailSender" type="string" required="true">
		<cfargument name="bugEmailRecipients" type="string" required="true">
		
		<cfscript>
			variables.bugEmailSender = arguments.bugEmailSender;
			variables.bugEmailRecipients = arguments.bugEmailRecipients;
		</cfscript>
		<cfreturn this>
	</cffunction>

	<cffunction name="notifyService" access="public" returntype="void" hint="Use this method to tell the bugTrackerService that an error has ocurred"> 
		<cfargument name="message" type="string" required="true">
		<cfargument name="exception" type="any" required="false" default="#structNew()#">
		<cfargument name="ExtraInfo" type="any" required="no" default="">
		<cfargument name="severityCode" type="string" required="false" default="#variables.defaultSeverityCode#">

		<cfset var shortMessage = "">
		<cfset var longMessage = "">
		<cfset var msgHash = "">
		<cfset var st = structNew()>

		<cfif arguments.severityCode neq "">
			<cfset arguments.message = "[#arguments.severityCode#] " & arguments.message>
		</cfif>

		<!--- compose short and full messages --->
		<cfset shortMessage = composeShortMessage(arguments.message, arguments.exception, arguments.extraInfo)>
		<cfset longMessage = composeFullMessage(arguments.message, arguments.exception, arguments.extraInfo)>

		<!--- send bug report via email --->
		<cfif variables.bugEmailRecipients neq "">
			<cfset sendEmail(arguments.message, longMessage)>	
		</cfif>

		<!--- add entry to coldfusion log --->	
		<cflog type="error" 
			   text="#shortMessage#" 
			   file="#variables.appName#_BugTrackingErrors">

		<!--- do any additional processing (to allow this cfc to be extended) --->		
		<cfset doCustomProcessing(arguments.message, arguments.exception, arguments.extraInfo)>		
				
	</cffunction>


	<cffunction name="sendEmail" access="private" hint="Sends the actual email message" returntype="void">
		<cfargument name="message" type="string" required="true">
		<cfargument name="longMessage" type="string" required="true">
		
		<cfmail to="#variables.bugEmailRecipients#" 
				from="#variables.bugEmailSender#" 
				subject="BUG REPORT: [#variables.appName#] [#variables.hostName#] #arguments.message#" 
				type="html">
			#arguments.longMessage#
		</cfmail>		
	</cffunction>


	<cffunction name="doCustomProcessing" access="private" hint="this method can be overloaded by descendants of this cfc to allow for custom handling of exception info">
		<cfargument name="message" type="string" required="true">
		<cfargument name="exception" type="any" required="false" default="#structNew()#">
		<cfargument name="ExtraInfo" type="any" required="no" default="">
	</cffunction>


	<cffunction name="composeShortMessage" access="private" returntype="string">
		<cfargument name="message" type="string" required="true">
		<cfargument name="exception" type="any" required="false" default="#structNew()#">
		<cfargument name="ExtraInfo" type="any" required="no" default="">
		<cfscript>
			var errorText = arguments.message;
			
			if(structKeyExists(arguments.exception,"message") and arguments.exception.message neq arguments.message)
				errorText = errorText & ". Message: " & arguments.exception.message;
				
			if(structKeyExists(arguments.exception, "detail") and arguments.exception.detail neq "")
				errorText = errorText & ". Details: " & arguments.exception.detail;
		</cfscript>
		<cfreturn errorText>
	</cffunction>


	<cffunction name="composeFullMessage" access="private" returntype="string">
		<cfargument name="message" type="string" required="true">
		<cfargument name="exception" type="any" required="false" default="#structNew()#">
		<cfargument name="ExtraInfo" type="any" required="no" default="">

		<cfset var tmpHTML = "">
		<cfset var i = 0>

		<cfsavecontent variable="tmpHTML">
			<h3>Exception Summary</h3>
			<cfoutput>
				<table style="font-size:11px;font-family:arial;">
					<tr>
						<td><b>Application:</b></td>
						<td>#variables.appName#</td>
					</tr>
					<tr>
						<td><b>Host:</b></td>
						<td>#variables.hostName#</td>
					</tr>
					<tr>
						<td><b>Server Date/Time:</b></td>
						<td>#lsDateFormat(now())# #lsTimeFormat(now())#</td>
					</tr>
					<cfif structKeyExists(arguments.exception,"message")>
						<tr>
							<td><b>Message:</b></td>
							<td>#arguments.exception.message#</td>
						</tr>
					</cfif>
					<cfif structKeyExists(arguments.exception,"detail")>
						<tr>
							<td><b>Detail:</b></td>
							<td>#arguments.exception.detail#</td>
						</tr>
					</cfif>
					<cfif structKeyExists(arguments.exception,"tagContext")>
						<tr valign="top">
							<td><b>Tag Context:</b></td>
							<td>
								<cfloop from="1" to="#arrayLen(arguments.exception.tagContext)#" index="i">
									<li>#htmlEditFormat(arguments.exception.tagContext[i].template)# [#arguments.exception.tagContext[i].line#]</li>
								</cfloop>
							</td>
						</tr>
					</cfif>
					<tr>
						<td><b>User Agent:</b></td>
						<td>#cgi.HTTP_USER_AGENT#</td>
					</tr>
					<tr>
						<td><b>Query String:</b></td>
						<td>#cgi.QUERY_STRING#</td>
					</tr>
					<tr valign="top">
						<td><strong>Coldfusion ID:</strong></td>
						<td>
							<cftry>
								[SESSION] &nbsp;&nbsp;&nbsp;&nbsp;
								CFID = #session.cfid#;
								CFTOKEN = #session.cftoken#
								JSessionID=#session.sessionID#
								<cfcatch type="any">
									<span style="color:red;">#cfcatch.message#</span>	
								</cfcatch>
							</cftry><br>
							
							<cftry>
								[CLIENT] &nbsp;&nbsp;&nbsp;&nbsp;
								CFID = #client.cfid#;
								CFTOKEN = #client.cftoken#
								<cfcatch type="any">
									<span style="color:red;">#cfcatch.message#</span>	
								</cfcatch>
							</cftry><br>
							
							<cftry>
								[COOKIES] &nbsp;&nbsp;&nbsp;&nbsp;
								CFID = #cookie.cfid#;
								CFTOKEN = #cookie.cftoken#
								<cfcatch type="any">
									<span style="color:red;">#cfcatch.message#</span>	
								</cfcatch>
							</cftry><br>
							
							<cftry>
								[J2EE SESSION] &nbsp;&nbsp;
								JSessionID = #session.JSessionID#;
								<cfcatch type="any">
									<span style="color:red;">#cfcatch.message#</span>	
								</cfcatch>
							</cftry>
						</td>
					</tr>					
				</table>
			</cfoutput>

			<h3>Exception Info</h3>
			<cfdump var="#arguments.exception#">
		
			<h3>Additional Info</h3>
			<cfdump var="#arguments.ExtraInfo#">
		</cfsavecontent>
		<cfreturn tmpHTML>
	</cffunction>
</cfcomponent>