<cfsetting enablecfoutputonly="true">
<cfprocessingdirective pageencoding="utf-8">

<cfif not StructKeyExists(url,'p')>
	<cfoutput><h2>No Project Selected!</h2></cfoutput><cfabort>
</cfif>

<cfif session.user.admin>
	<cfset project = application.project.get(projectID=url.p)>
<cfelse>
	<cfset project = application.project.get(session.user.userid,url.p)>
</cfif>

<cfif not session.user.admin and not project.mstone_view eq 1>
	<cfoutput><h2>You do not have permission to access milestones!!!</h2></cfoutput>
	<cfabort>
</cfif>

<cfif StructKeyExists(url,"c")> <!--- mark completed --->
	<cfset application.milestone.markCompleted(url.c,url.p)>
	<cfset application.activity.add(createUUID(),url.p,session.user.userid,'Milestone',url.c,url.ms,'marked completed')>
<cfelseif StructKeyExists(url,"a")> <!--- mark active --->
	<cfset application.milestone.markActive(url.a,url.p)>
	<cfset application.activity.add(createUUID(),url.p,session.user.userid,'Milestone',url.a,url.ms,'reactivated')>
<cfelseif StructKeyExists(url,"d")> <!--- delete --->
	<cfset application.milestone.delete(url.d,url.p)>
	<cfset application.activity.add(createUUID(),url.p,session.user.userid,'Milestone',url.d,url.d,'deleted')>
</cfif>

<cfset milestones1 = application.milestone.get(url.p,'','overdue')>
<cfset milestones2 = application.milestone.get(url.p,'','upcoming')>
<cfset milestones3 = application.milestone.get(url.p,'','completed')>
<cfset messages = application.message.get(url.p)>
<cfset todolists = application.todolist.get(url.p)>
<cfset issues = application.issue.get(url.p)>

<!--- Loads header/footer --->
<cfmodule template="#application.settings.mapping#/tags/layout.cfm" templatename="main" title="#project.name# &raquo; Milestones" project="#project.name#" projectid="#url.p#" svnurl="#project.svnurl#">

<cfoutput>
<div id="container">
<cfif project.recordCount>
	<!--- left column --->
	<div class="left">
		<div class="main">

				<div class="header">
					<h2 class="milestone">All milestones &nbsp;<span style="font-size:.75em;font-weight:normal;color:##666;">Today is #LSDateFormat(DateAdd("h",session.tzOffset,DateConvert("local2Utc",Now())),"d mmm")#</span></h2>
				</div>
				<div class="content">
					<div class="wrapper">
					<cfif milestones1.recordCount or milestones2.recordCount or milestones3.recordCount>			
					
					<cfif milestones1.recordCount>		
						<div class="milestones late">
						<div class="header late">Late</div>
						<cfloop query="milestones1">
						<cfset daysago = DateDiff("d",dueDate,Now())>
							<div class="milestone">
							<div class="date late"><span class="b"><cfif daysago eq 0>Today<cfelseif daysago eq 1>Yesterday<cfelse>#daysago# days ago</cfif></span><cfif isDate(dueDate)> (#LSDateFormat(dueDate,"dddd, d mmmm, yyyy")#)</cfif><cfif userid neq 0><span style="color:##666;"> - Assigned to #firstName# #lastName#</span></cfif></div>
							<div id="m#milestoneid#" style="display:none;" class="markcomplete">Moving to Completed - just a second...</div>
							<cfif session.user.admin or project.mstone_edit eq 1>
								<h3><input type="checkbox" name="milestoneid" value="#milestoneid#" onclick="$('##m#milestoneid#').show();window.location='#cgi.script_name#?p=#url.p#&amp;c=#milestoneid#&amp;ms=#URLEncodedFormat(name)#';" style="vertical-align:middle;" /> 
									<a href="milestone.cfm?p=#url.p#&amp;m=#milestoneid#">#name#</a> 
									<span style="font-size:.65em;font-weight:normal;">[<a href="editMilestone.cfm?p=#url.p#&amp;m=#milestoneid#" class="edit">edit</a> / <a href="#cgi.script_name#?p=#url.p#&amp;d=#milestoneID#" class="delete" onclick="return confirm('Are you sure you wish to delete this milestone?');">delete</a>
									<cfif session.user.admin or project.mstone_comment eq 1>
									/ <a href="milestone.cfm?p=#url.p#&amp;m=#milestoneID#" class="comment"><cfif commentCount gt 0>#commentCount# Comments<cfelse>Post the first comment</cfif></a>
									</cfif>
									]</span></h3>
							<cfelse>
								<h3>#name#</h3>
								<cfif project.mstone_comment eq 1>
									<span style="font-size:.65em;font-weight:normal;">[<a href="milestone.cfm?p=#url.p#&amp;m=#milestoneID#" class="comment"><cfif commentCount gt 0>#commentCount# Comments<cfelse>Post the first comment</cfif></a>]</span>
								</cfif>
							</cfif>
							<cfif compare(description,'')><div class="desc">#description#</div></cfif>
							
							<cfquery name="msgs" dbtype="query">
								select messageid,title,stamp,firstName,lastName,commentcount from messages where milestoneid = '#milestoneid#'
							</cfquery>
							<cfif msgs.recordCount>
							<h5 class="sub">Messages:</h5>
							<ul class="sub">
							<cfloop query="msgs">
							<li class="sub"><a href="message.cfm?p=#url.p#&amp;m=#messageid#">#title#</a> - Posted #LSDateFormat(DateAdd("h",session.tzOffset,stamp),"d mmm, yyyy")# by #firstName# #lastName#<cfif commentcount gt 0> <span class="i">(#commentcount# comments)</span></cfif></li>
							</cfloop>
							</ul>
							</cfif>
							
							<cfquery name="tl" dbtype="query">
								select todolistid,title,added,firstName,lastName,completed_count,uncompleted_count 
								from todolists where milestoneid = '#milestoneid#'
							</cfquery>
							<cfif tl.recordCount>
							<h5 class="sub">To-Do Lists:</h5>
							<ul class="sub">
							<cfloop query="tl">
							<li class="sub"><a href="todos.cfm?p=#url.p#&amp;t=#todolistid#">#title#</a> - #completed_count# complete / #uncompleted_count# pending - Added #LSDateFormat(DateAdd("h",session.tzOffset,added),"d mmm, yyyy")#<cfif compare(firstName,'') or compare(lastName,'')> for #firstName# #lastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>
						
							<cfquery name="iss1" dbtype="query">
								select issueID, shortID, issue, status, type, severity, created, assignedFirstName, assignedLastName
								from issues where milestoneid = '#milestoneid#' and status in ('New','Open','Accepted','Assigned')
							</cfquery>
							<cfquery name="iss2" dbtype="query">
								select issueID, shortID, issue, status, type, severity, created, assignedFirstName, assignedLastName
								from issues where milestoneid = '#milestoneid#' and status in ('Resolved','Closed')
							</cfquery>
							<cfif iss1.recordCount>
							<h5 class="sub">New/Open Issues:</h5>
							<ul class="sub">
							<cfloop query="iss1">
							<li class="sub"><a href="issue.cfm?p=#url.p#&amp;i=#issueid#">#shortid# - #issue#</a> (#status# #type# / #severity#) - Added #LSDateFormat(DateAdd("h",session.tzOffset,created),"d mmm, yyyy")#<cfif compare(assignedFirstName,'') or compare(assignedLastName,'')> for #assignedFirstName# #assignedLastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>						
							<cfif iss2.recordCount>
							<h5 class="sub">Resolved/Closed Issues:</h5>
							<ul class="sub">
							<cfloop query="iss2">
							<li class="sub"><a href="issue.cfm?p=#url.p#&amp;i=#issueid#">#shortid# - #issue#</a> (#status# #type# / #severity#) - Added #LSDateFormat(DateAdd("h",session.tzOffset,created),"d mmm, yyyy")#<cfif compare(assignedFirstName,'') or compare(assignedLastName,'')> for #assignedFirstName# #assignedLastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>			
							
							</div>	
						</cfloop>
						</div>					
					</cfif>
					
					
		
					<cfif milestones2.recordCount>		
						<div class="milestones upcoming">
						<div class="header upcoming">Upcoming</div>
						<cfloop query="milestones2">
						<cfset daysago = DateDiff("d",CreateDate(year(Now()),month(Now()),day(Now())),dueDate)>
							<div class="milestone">
							<div class="date upcoming"><span class=" b"><cfif daysago eq 0>Today<cfelseif daysago eq 1>Tomorrow<cfelse>#daysago# days away</cfif></span><cfif isDate(dueDate)> (#LSDateFormat(dueDate,"dddd, d mmmm, yyyy")#)</cfif><cfif userid neq 0><span style="color:##666;"> - Assigned to #firstName# #lastName#</span></cfif></div>
							<div id="m#milestoneid#" style="display:none;" class="markcomplete">Moving to Completed - just a second...</div>
							<cfif session.user.admin or project.mstone_edit eq 1>
								<h3><input type="checkbox" name="milestoneid" value="#milestoneid#" onclick="$('##m#milestoneid#').show();window.location='#cgi.script_name#?p=#url.p#&amp;c=#milestoneid#&amp;ms=#URLEncodedFormat(name)#';" style="vertical-align:middle;" /> 
									<a href="milestone.cfm?p=#url.p#&amp;m=#milestoneid#">#name#</a> 
									<span style="font-size:.65em;font-weight:normal;">[<a href="editMilestone.cfm?p=#url.p#&amp;m=#milestoneid#" class="edit">edit</a> / <a href="#cgi.script_name#?p=#url.p#&amp;d=#milestoneID#" class="delete" onclick="return confirm('Are you sure you wish to delete this milestone?');">delete</a>
									<cfif project.mstone_comment>
									/ <a href="milestone.cfm?p=#url.p#&amp;m=#milestoneID#" class="comment"><cfif commentCount gt 0>#commentCount# Comments<cfelse>Post the first comment</cfif></a>
									</cfif>
									]</span></h3>
							<cfelse>
								<h3>#name#</h3>
								<cfif project.mstone_comment>
									<span style="font-size:.65em;font-weight:normal;">[<a href="milestone.cfm?p=#url.p#&amp;m=#milestoneID#" class="comment"><cfif commentCount gt 0>#commentCount# Comments<cfelse>Post the first comment</cfif></a>]</span>
								</cfif>
							</cfif>

							<cfif compare(description,'')><div class="desc">#description#</div></cfif>
							
							<cfquery name="msgs" dbtype="query">
								select messageid,title,stamp,firstName,lastName,commentcount from messages where milestoneid = '#milestoneid#'
							</cfquery>
							<cfif msgs.recordCount>
							<h5 class="sub">Messages:</h5>
							<ul class="sub">
							<cfloop query="msgs">
							<li class="sub"><a href="message.cfm?p=#url.p#&amp;m=#messageid#">#title#</a> - Posted #LSDateFormat(DateAdd("h",session.tzOffset,stamp),"d mmm, yyyy")# by #firstName# #lastName#<cfif commentcount gt 0> <span class="i">(#commentcount# comments)</span></cfif></li>
							</cfloop>
							</ul>
							</cfif>
							
							<cfquery name="tl" dbtype="query">
								select todolistid,title,added,firstName,lastName from todolists where milestoneid = '#milestoneid#'
							</cfquery>
							<cfif tl.recordCount>
							<h5 class="sub">To-Do List:</h5>
							<ul class="sub">
							<cfloop query="tl">
							<li class="sub"><a href="todos.cfm?p=#url.p#&amp;tlid=#todolistid#">#title#</a> - Added #LSDateFormat(DateAdd("h",session.tzOffset,added),"d mmm, yyyy")#<cfif compare(firstName,'') or compare(lastName,'')> for #firstName# #lastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>
						
							<cfquery name="iss1" dbtype="query">
								select issueID, shortID, issue, status, type, severity, created, assignedFirstName, assignedLastName
								from issues where milestoneid = '#milestoneid#' and status in ('New','Open','Accepted','Assigned')
							</cfquery>
							<cfquery name="iss2" dbtype="query">
								select issueID, shortID, issue, status, type, severity, created, assignedFirstName, assignedLastName
								from issues where milestoneid = '#milestoneid#' and status in ('Resolved','Closed')
							</cfquery>
							<cfif iss1.recordCount>
							<h5 class="sub">New/Open Issues:</h5>
							<ul class="sub">
							<cfloop query="iss1">
							<li class="sub"><a href="issue.cfm?p=#url.p#&amp;i=#issueid#">#shortid# - #issue#</a> (#status# #type# / #severity#) - Added #LSDateFormat(DateAdd("h",session.tzOffset,created),"d mmm, yyyy")#<cfif compare(assignedFirstName,'') or compare(assignedLastName,'')> for #assignedFirstName# #assignedLastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>							
							<cfif iss2.recordCount>
							<h5 class="sub">Resolved/Closed Issues:</h5>
							<ul class="sub">
							<cfloop query="iss2">
							<li class="sub"><a href="issue.cfm?p=#url.p#&amp;i=#issueid#">#shortid# - #issue#</a> (#status# #type# / #severity#) - Added #LSDateFormat(DateAdd("h",session.tzOffset,created),"d mmm, yyyy")#<cfif compare(assignedFirstName,'') or compare(assignedLastName,'')> for #assignedFirstName# #assignedLastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>							
						
							</div>	
						</cfloop>
						</div>					
					</cfif>
					
					
					
					<cfif milestones3.recordCount>		
						<div class="milestones completed">
						<div class="header completed">Completed</div>
						<cfloop query="milestones3">
							<div class="milestone">
							<div class="date late"><span class="completed b"><cfif isDate(dueDate)>#LSDateFormat(dueDate,"dddd, mmmm d, yyyy")#</cfif></span><cfif userid neq 0><span style="color:##666;"> - Assigned to #firstName# #lastName#</span></cfif></div>
							<div id="m#milestoneid#" style="display:none;" class="markcomplete">Moving to <cfif DateDiff("d",dueDate,Now())>Late<cfelse>Upcoming</cfif> - just a second...</div>
							<cfif session.user.admin or project.mstone_edit eq 1>
								<h3><input type="checkbox" name="milestoneid" value="#milestoneid#" onclick="$('##m#milestoneid#').show();window.location='#cgi.script_name#?p=#url.p#&amp;a=#milestoneid#&amp;ms=#URLEncodedFormat(name)#';" style="vertical-align:middle;" checked="checked" /> 
									<a href="milestone.cfm?p=#url.p#&amp;m=#milestoneid#">#name#</a> 
									<span style="font-size:.65em;font-weight:normal;">[<a href="editMilestone.cfm?p=#url.p#&amp;m=#milestoneid#" class="edit">edit</a> / <a href="#cgi.script_name#?p=#url.p#&amp;d=#milestoneID#" class="delete" onclick="return confirm('Are you sure you wish to delete this milestone?');">delete</a>
									<cfif project.mstone_comment>
									/ <a href="milestone.cfm?p=#url.p#&amp;m=#milestoneID#" class="comment"><cfif commentCount gt 0>#commentCount# Comments<cfelse>Post the first comment</cfif></a>
									</cfif>
									]</span></h3>
							<cfelse>
								<h3>#name#</h3>
								<cfif project.mstone_comment>
									<span style="font-size:.65em;font-weight:normal;">[<a href="milestone.cfm?p=#url.p#&amp;m=#milestoneID#" class="comment"><cfif commentCount gt 0>#commentCount# Comments<cfelse>Post the first comment</cfif></a>]</span>
								</cfif>
							</cfif>

							<cfif compare(description,'')><div class="desc">#description#</div></cfif>
							
							<cfquery name="msgs" dbtype="query">
								select messageid,title,stamp,firstName,lastName,commentcount from messages where milestoneid = '#milestoneid#'
							</cfquery>
							<cfif msgs.recordCount>
							<h5 class="sub">Messages:</h5>
							<ul class="sub">
							<cfloop query="msgs">
							<li class="sub"><a href="message.cfm?p=#url.p#&amp;m=#messageid#">#title#</a> - Posted #LSDateFormat(DateAdd("h",session.tzOffset,stamp),"d mmm, yyyy")# by #firstName# #lastName#<cfif commentcount gt 0> <span class="i">(#commentcount# comments)</span></cfif></li>
							</cfloop>
							</ul>
							</cfif>
							
							<cfquery name="tl" dbtype="query">
								select todolistid,title,added,firstName,lastName from todolists where milestoneid = '#milestoneid#'
							</cfquery>
							<cfif tl.recordCount>
							<h5 class="sub">To-Do Lists:</h5>
							<ul class="sub">
							<cfloop query="tl">
							<li class="sub"><a href="todos.cfm?p=#url.p#&amp;tlid=#todolistid#">#title#</a> - Added #LSDateFormat(DateAdd("h",session.tzOffset,added),"d mmm, yyyy")#<cfif compare(firstName,'') or compare(lastName,'')> for #firstName# #lastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>

							<cfquery name="iss1" dbtype="query">
								select issueID, shortID, issue, status, type, severity, created, assignedFirstName, assignedLastName
								from issues where milestoneid = '#milestoneid#' and status in ('New','Open','Accepted','Assigned')
							</cfquery>
							<cfquery name="iss2" dbtype="query">
								select issueID, shortID, issue, status, type, severity, created, assignedFirstName, assignedLastName
								from issues where milestoneid = '#milestoneid#' and status in ('Resolved','Closed')
							</cfquery>							
							<cfif iss1.recordCount>
							<h5 class="sub">New/Open Issues:</h5>
							<ul class="sub">
							<cfloop query="iss1">
							<li class="sub"><a href="issue.cfm?p=#url.p#&amp;i=#issueid#">#shortid# - #issue#</a> (#status# #type# / #severity#) - Added #LSDateFormat(DateAdd("h",session.tzOffset,created),"d mmm, yyyy")#<cfif compare(assignedFirstName,'') or compare(assignedLastName,'')> for #assignedFirstName# #assignedLastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>	
							<cfif iss2.recordCount>
							<h5 class="sub">Resolved/Closed Issues:</h5>
							<ul class="sub">
							<cfloop query="iss2">
							<li class="sub"><a href="issue.cfm?p=#url.p#&amp;i=#issueid#">#shortid# - #issue#</a> (#status# #type# / #severity#) - Added #LSDateFormat(DateAdd("h",session.tzOffset,created),"d mmm, yyyy")#<cfif compare(assignedFirstName,'') or compare(assignedLastName,'')> for #assignedFirstName# #assignedLastName#</cfif></li>
							</cfloop>
							</ul>	
							</cfif>	
							
							</div>	
						</cfloop>
						</div>					
					</cfif>							
					
					
					<cfelse>
					<div class="warn">No milestones have been added.</div>
					</cfif>
					</div>
				</div>
			
		</div>
		<div class="bottom">&nbsp;</div>
		<div class="footer">
			<cfinclude template="footer.cfm">
		</div>	  
	</div>

	<!--- right column --->
	<div class="right">
		<cfif compare(project.logo_img,'')>
			<img src="#application.settings.userFilesMapping#/projects/#project.logo_img#" border="0" alt="#project.name#" class="projlogo" />
		</cfif>

		<cfif session.user.admin or project.mstone_edit eq 1>
		<h3><a href="editMilestone.cfm?p=#url.p#" class="add">Add a new milestone</a></h3><br />
		</cfif>	
	</div>
<cfelse>
	<div class="alert">Project Not Found.</div>
</cfif>
</div>
</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly="false">