<cfsetting enablecfoutputonly="true">
<cfprocessingdirective pageencoding="utf-8">

<!---
	Filename: 		reportsPDF.cfm
	Designers:		Emilie McGregor
	Created: 		2/3/2009 14:31:28 PM
	Description:	PDF for displaying reports
--->

<cfparam name="form.c" default="">
<cfparam name="form.u" default="">
<cfparam name="form.p" default="">
<cfparam name="url.f" default="">
<cfparam name="form.report" default="all">
<cfparam name="form.Invoice" default="">
<cfparam name="form.startDate" default="">
<cfparam name="form.endDate" default="">
<cfparam name="form.invoiceType" default="full">

<cfif compare(form.p,'')>
	<cfset projects = application.project.get(projectID=form.p) />	
	<cfset project = projects />			
<cfelseif form.report IS 'client'>
	<cfset clients = application.client.get() />
	<cfif compare(form.Invoice,'')  >
		<cfset projects = application.project.get(clientID=form.c) />
	</cfif>
<cfelseif form.report IS 'programmer'>
	<cfset users = application.user.get() />
	<cfif compare(form.Invoice,'')  >
		<cfset projects = application.project.get(userID=form.u) />
	</cfif>
<cfelseif form.report IS 'all'>
	<cfset projects = application.project.get() />
</cfif>

<cfif compare(form.startDate,'') AND NOT compare(form.endDate,'')>
	<cfset form.endDate = #LSDateFormat(Now(), "mm/dd/yyyy")#>
</cfif>

<cfdocument format="pdf">
<cfoutput>
<link rel="stylesheet" href="#application.settings.mapping#/css/all_styles.css" media="all" type="text/css" />
<style type="text/css">
	body{ background:##fff; }
</style>	

<table style="width:100%;">
	<tr>
		<td style="text-align:left; vertical-align:top;">
			<cfif compare(application.settings.invoice_logo,'')>
				<img src="#application.settings.userFilesMapping#/company/#application.settings.invoice_logo#" alt="#application.settings.company_name# Company Logo" />
			<cfelse>
				<h1>#application.settings.company_name#</h1>
			</cfif>
			<br/><br/>
		</td>
		<td style="text-align:right; vertical-align:top;">
			<h2>Report</h2>
			<cfif compare(form.startDate,'') AND compare(form.endDate,'') >
			<h4>Services Rendered</h4>
			<h4>#startDate# - #endDate#</h4>
			</cfif>
		</td>
	</tr>
	<tr>
		<td style="text-align:left; vertical-align:top;">
			<h4>#application.settings.company_name#</h4>
			<br/>
		</td>
		<td style="text-align:right; vertical-align:top;">
			Date: #LSDateFormat(Now(), "mmmm dd, yyyy")#
		</td>
	</tr>						

	<cfset timelines = application.timetrack.get(projectID=form.p,userID=form.u,clientID=form.c,startDate=form.startDate,endDate=form.endDate) />
	
	<cfquery name="byClient" dbtype="query">
		SELECT		SUM(CAST(hours as DECIMAL)) as totalHours, client
		FROM 		timelines
		GROUP BY	client
	</cfquery>
		
	<tr>
		<td colspan="2">
			<h3>Breakdown of Hours by Client</h3>
		</td>
	</tr>
	<tr>
		<td>
		<cfchart format="png" showBorder = "no" chartheight=300 chartwidth=300 xaxisTitle="" yaxisTitle="Total"
			dataBackgroundColor="FFFFFF" backgroundColor="FFFFFF" foregroundColor="000000">
			<cfchartseries type="pie" paintStyle="light" colorlist="##660099, ##9999FF">
				<cfloop index="i" from="1" to="#byClient.recordcount#" >
					<cfif byClient.client[i] IS "">
						<cfset label = "Miscellaneous" />
					<cfelse>
						<cfset label = byClient.client[i] />
					</cfif>
					<cfchartdata item="#label#" value="#byClient.totalHours[i]# ">
				</cfloop>
			</cfchartseries>
		</cfchart>
		</td>
		<td>
			<table class="clean full" id="time" style="border-top:2px solid ##000;">
			 	<thead>
					<tr>
						<th>Client</th>
						<th>Hours</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="byClient">
					<tr>
						<td>#client#</td>
						<td>#totalHours#</td>
					</tr>
					</cfloop>
				</tbody>
			</table>	
		</td>
	</tr>	
		
	<cfquery name="byProject" dbtype="query">
		SELECT		SUM(CAST(hours as DECIMAL)) as totalHours, name
		FROM 		timelines
		GROUP BY	name
	</cfquery>										
	
	<tr>
		<td colspan="2">
			<h3>Breakdown of Hours by Project</h3>
		</td>
	</tr>
	<tr>
		<td>
		<cfchart format="png" showBorder="no" chartheight=300 chartwidth=300 xaxisTitle="" yaxisTitle="Total"
			dataBackgroundColor="FFFFFF" backgroundColor="FFFFFF" foregroundColor="000000">
			<cfchartseries type="pie" paintStyle="light" colorlist="##660099, ##9999FF">
				<cfloop index="i" from="1" to="#byProject.recordcount#">
					<cfchartdata item="#byProject.name[i]#" value="#byProject.totalHours[i]# ">
				</cfloop>
			</cfchartseries>
		</cfchart>
		</td>
		<td>
			<table class="clean full" id="time" style="border-top:2px solid ##000;">
			 	<thead>
					<tr>
						<th>Project</th>
						<th>Hours</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="byProject">
					<tr>
						<td>#name#</td>
						<td>#totalHours#</td>
					</tr>
					</cfloop>
				</tbody>
			</table>
		</td>
	</tr>
	<tr>
		<td colspan="2">
		<cfdocumentitem type="pagebreak" />
		</td>
	</tr>
		
	<cfquery name="byUser" dbtype="query">
		SELECT		SUM(CAST(hours as DECIMAL)) as totalHours, firstName, lastName
		FROM 		timelines
		GROUP BY	firstName, lastName
	</cfquery>
	
	<tr>	
		<td colspan="2">
			<h3>Breakdown of Hours by Programmer</h3>
		</td>
	</tr>
	<tr>
	
	<cfif byUser.RecordCount>
		<td>
		<cfchart format="png" showBorder="no" chartheight=300 chartwidth=300 xaxisTitle="" yaxisTitle="Total"
			dataBackgroundColor="FFFFFF" backgroundColor="FFFFFF" foregroundColor="000000">
			<cfchartseries type="pie" paintStyle="light" colorlist="##660099, ##9999FF">
				<cfloop index="i" from="1" to="#byUser.recordcount#" >
					<cfchartdata item="#byUser.firstName[i]# #byUser.lastName[i]#" value="#byUser.totalHours[i]# ">
				</cfloop>
			</cfchartseries>
		</cfchart>
		</td>
		<td>
			<table class="clean full" id="time" style="border-top:2px solid ##000;">
			 	<thead>
					<tr>
						<th>Programmer</th>
						<th>Hours</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="byUser">
					<tr>
						<td>#firstName# #lastName#</td>
						<td>#totalHours#</td>
					</tr>
					</cfloop>
				</tbody>
			</table>	
		</td>
	<cfelse>
		<td colspan="2">
		<br/>
		<div class="alert">No time tracking records found for that <cfif StructKeyExists(form,"startDay")>period<cfelse>item</cfif>.</div>
		<br/>
		</td>
	</cfif>
	</tr>
	
	<cfquery name="byCategory" dbtype="query">
		SELECT		SUM(CAST(hours as DECIMAL)) as totalHours, category
		FROM 		timelines
		GROUP BY	category
	</cfquery>
	<tr>
		<td colspan="2">
			<h3>Breakdown of Hours by Category of Work</h3>
		</td>
	</tr>
	<tr>
		<td>
		 <cfchart format="png" showBorder="no" chartheight=300 chartwidth=300 xaxisTitle="" yaxisTitle="Total"
			dataBackgroundColor="FFFFFF" backgroundColor="FFFFFF" foregroundColor="000000">
			<cfchartseries type="pie" paintStyle="light" colorlist="##660099, ##9999FF">
				<cfloop index="i" from="1" to="#byCategory.recordcount#">
					<cfif byCategory.category[i] IS "">
						<cfset label = "Miscellaneous" />
					<cfelse>
						<cfset label = byCategory.category[i] />
					</cfif>
					<cfchartdata item="#label#" value="#byCategory.totalHours[i]# ">
				</cfloop>
			</cfchartseries>
		</cfchart>
		</td>
		<td>
			<table class="clean full" id="time" style="border-top:2px solid ##000;">
			 	<thead>
					<tr>
						<th>Category</th>
						<th>Hours</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="byCategory">
					<tr>
						<td><cfif category IS NOT "">#category#<cfelse>Miscellaneous</cfif></td>
						<td>#totalHours#</td>
					</tr>
					</cfloop>
				</tbody>
			</table>	
		</td>
	</tr>		
</table>
</cfoutput>
</cfdocument>
<cfsetting enablecfoutputonly="false">