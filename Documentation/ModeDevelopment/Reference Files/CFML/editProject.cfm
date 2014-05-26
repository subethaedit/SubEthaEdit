<cfsetting enablecfoutputonly="true">
<cfprocessingdirective pageencoding="utf-8">

<cfif StructKeyExists(url,"p") or StructKeyExists(form,"projectid")>
	<cfif StructKeyExists(url,"p")>
		<cfset userRole = application.role.get(session.user.userid,url.p)>
	<cfelse>
		<cfset userRole = application.role.get(session.user.userid,form.projectid)>
	</cfif>
	<cfif not session.user.admin and not userRole.admin eq 1>
		<cfoutput><h2>Admin Access Only!!!</h2></cfoutput>
		<cfabort>
	</cfif>
</cfif>

<cfparam name="form.display" default="0">
<cfparam name="form.from" default="">
<cfparam name="form.logo_img" default="">
<cfparam name="form.allow_reg" default="0">
<cfparam name="form.allow_def_rates" default="0">
<cfparam name="form.reg_file_view" default="0">
<cfparam name="form.reg_file_edit" default="0">
<cfparam name="form.reg_file_comment" default="0">
<cfparam name="form.reg_issue_view" default="0">
<cfparam name="form.reg_issue_edit" default="0">
<cfparam name="form.reg_issue_assign" default="0">
<cfparam name="form.reg_issue_resolve" default="0">
<cfparam name="form.reg_issue_close" default="0">
<cfparam name="form.reg_issue_comment" default="0">
<cfparam name="form.reg_msg_view" default="0">
<cfparam name="form.reg_msg_edit" default="0">
<cfparam name="form.reg_msg_comment" default="0">
<cfparam name="form.reg_mstone_view" default="0">
<cfparam name="form.reg_mstone_edit" default="0">
<cfparam name="form.reg_mstone_comment" default="0">
<cfparam name="form.reg_todolist_view" default="0">
<cfparam name="form.reg_todolist_edit" default="0">
<cfparam name="form.reg_todo_edit" default="0">
<cfparam name="form.reg_todo_comment" default="0">
<cfparam name="form.reg_time_view" default="0">
<cfparam name="form.reg_time_edit" default="0">
<cfparam name="form.reg_bill_view" default="0">
<cfparam name="form.reg_bill_edit" default="0">
<cfparam name="form.reg_bill_rates" default="0">
<cfparam name="form.reg_bill_invoices" default="0">
<cfparam name="form.reg_bill_markpaid" default="0">
<cfparam name="form.reg_svn" default="0">
<cfparam name="form.tab_files" default="0">
<cfparam name="form.tab_issues" default="0">
<cfparam name="form.tab_msgs" default="0">
<cfparam name="form.tab_mstones" default="0">
<cfparam name="form.tab_todos" default="0">
<cfparam name="form.tab_time" default="0">
<cfparam name="form.tab_billing" default="0">
<cfparam name="form.tab_svn" default="0">
<cfparam name="form.issue_svn_link" default="0">
<cfparam name="form.issue_timetrack" default="0">
<cfparam name="form.googlecal" default="">
<cfif StructKeyExists(url,"from")>
	<cfset form.from = url.from>
</cfif>

<cfif StructKeyExists(url,"rmvimg")>
	<cftry>
			<cffile action="delete" file="#application.userFilesPath#projects/#form.old_image#">
			<cfcatch></cfcatch>
	</cftry>
	<cfset application.project.removeLogo(url.p)>
</cfif>

<cfif (StructKeyExists(form,"submit") and not compare(form.submit,'Update Project') and compare(form.imagefile,'')) or (StructKeyExists(form,"submit") and not compare(form.submit,'Add Project') and compare(form.imagefile,''))>
	<cfif compare(form.old_image,'')>
		<cftry>
			<cffile action="delete" file="#application.userFilesPath#projects/#form.old_image#">
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
	<cffile action="upload" accept="image/gif,image/jpg,image/jpeg,image/png" filefield="imagefile"
		destination = "#application.userFilesPath#projects" nameConflict = "MakeUnique">		
	<cfset logoimg = cffile.serverFile>
<cfelse>
	<cfset logoimg = "">
</cfif>
	
<cfif StructKeyExists(form,"submit") and not compare(form.submit,'Update Project')> <!--- update project --->
	<cfif not compare(form.description,'<br />')>
		<cfset form.description = "">
	</cfif>
	<cfset application.project.update(form.projectid,form.ownerID,form.name,form.description,form.display,form.clientID,form.status,form.ticketPrefix,form.svnurl,form.svnuser,form.svnpass,logoimg,form.allow_reg,form.allow_def_rates,form.reg_file_view,form.reg_file_edit,form.reg_file_comment,form.reg_issue_view,form.reg_issue_edit,form.reg_issue_assign,form.reg_issue_resolve,form.reg_issue_close,form.reg_issue_comment,form.reg_msg_view,form.reg_msg_edit,form.reg_msg_comment,form.reg_mstone_view,form.reg_mstone_edit,form.reg_mstone_comment,form.reg_todolist_view,form.reg_todolist_edit,form.reg_todo_edit,form.reg_todo_comment,form.reg_time_view,form.reg_time_edit,form.reg_bill_view,form.reg_bill_edit,form.reg_bill_rates,form.reg_bill_invoices,form.reg_bill_markpaid,form.reg_svn,form.tab_files,form.tab_issues,form.tab_msgs,form.tab_mstones,form.tab_todos,form.tab_time,form.tab_billing,form.tab_svn,form.issue_svn_link,form.issue_timetrack,form.googlecal)>
	<cfset application.activity.add(createUUID(),form.projectID,session.user.userid,'Project',form.projectID,form.name,'edited')>
	<cfif not compare(form.from,'admin')>
		<cflocation url="./admin/projects.cfm" addtoken="false">
	<cfelse>
		<cflocation url="project.cfm?p=#form.projectID#" addtoken="false">
	</cfif>
<cfelseif StructKeyExists(form,"submit") and not compare(form.submit,'Add Project')> <!--- add project --->
	<cfif not compare(form.description,'<br />')>
		<cfset form.description = "">
	</cfif>
	<cfset application.project.add(form.projectID,form.ownerid,form.name,form.description,form.display,form.clientID,form.status,form.ticketPrefix,form.svnurl,form.svnuser,form.svnpass,logoimg,form.allow_reg,form.allow_def_rates,form.reg_file_view,form.reg_file_edit,form.reg_file_comment,form.reg_issue_view,form.reg_issue_edit,form.reg_issue_assign,form.reg_issue_resolve,form.reg_issue_close,form.reg_issue_comment,form.reg_msg_view,form.reg_msg_edit,form.reg_msg_comment,form.reg_mstone_view,form.reg_mstone_edit,form.reg_mstone_comment,form.reg_todolist_view,form.reg_todolist_edit,form.reg_todo_edit,form.reg_todo_comment,form.reg_time_view,form.reg_time_edit,form.reg_bill_view,form.reg_bill_edit,form.reg_bill_rates,form.reg_bill_invoices,form.reg_bill_markpaid,form.reg_svn,form.tab_files,form.tab_issues,form.tab_msgs,form.tab_mstones,form.tab_todos,form.tab_time,form.tab_billing,form.tab_svn,form.issue_svn_link,form.issue_timetrack,form.googlecal,session.user.userid)>
	<cfset application.role.add(form.projectID,session.user.userid,'1')>
	<cfset application.notify.add(session.user.userid,form.projectID)>	
	<cfset application.activity.add(createUUID(),form.projectID,session.user.userid,'Project',form.projectID,form.name,'added')>
	<cfset session.user.projects = application.project.get(session.user.userid)>
	<cfif not compare(form.from,'admin')>
		<cflocation url="./admin/projects.cfm" addtoken="false">
	<cfelse>
		<cflocation url="project.cfm?p=#form.projectID#" addtoken="false">
	</cfif>
<cfelseif StructKeyExists(url,"del") and hash(url.p) eq url.ph> <!--- delete project --->
	<cfset application.project.delete(url.p)>
	<cfset session.user.projects = application.project.get(session.user.userid)>
	<cflocation url="index.cfm" addtoken="false">
</cfif>

<cfparam name="projID" default="">
<cfparam name="form.name" default="">
<cfparam name="form.description" default="">
<cfparam name="form.ownerID" default="">
<cfparam name="form.clientID" default="">
<cfparam name="form.clientName" default="&lt;none&gt;">
<cfparam name="form.status" default="">
<cfparam name="form.ticketPrefix" default="">
<cfparam name="form.svnurl" default="">
<cfparam name="form.svnuser" default="">
<cfparam name="form.svnpass" default="">
<cfparam name="form.googlecal" default="">
<cfparam name="title_action" default="Add">

<cfif StructKeyExists(url,"p")>
	<cfset projID = url.p>
	<cfset thisProject = application.project.getDistinct(url.p)>
	<cfset form.ownerID = thisProject.ownerID>
	<cfset form.name = thisProject.name>
	<cfset form.description = thisProject.description>
	<cfset form.display = thisProject.display>
	<cfset form.clientID = thisProject.clientID>
	<cfset form.clientName = thisProject.clientName>
	<cfset form.status = thisProject.status>
	<cfset form.ticketPrefix = thisProject.ticketPrefix>
	<cfset form.svnurl = thisProject.svnurl>
	<cfset form.svnuser = thisProject.svnuser>
	<cfset form.svnpass = thisProject.svnpass>
	<cfset form.logo_img = thisProject.logo_img>
	<cfset form.old_image = thisProject.logo_img>
	<cfset form.allow_reg = thisProject.allow_reg>
	<cfset form.allow_def_rates = thisProject.allow_def_rates>
	<cfset form.reg_file_view = thisProject.reg_file_view>
	<cfset form.reg_file_edit = thisProject.reg_file_edit>
	<cfset form.reg_file_comment = thisProject.reg_file_comment>
	<cfset form.reg_issue_view = thisProject.reg_issue_view>
	<cfset form.reg_issue_edit = thisProject.reg_issue_edit>
	<cfset form.reg_issue_assign = thisProject.reg_issue_assign>
	<cfset form.reg_issue_resolve = thisProject.reg_issue_resolve>
	<cfset form.reg_issue_close = thisProject.reg_issue_close>
	<cfset form.reg_issue_comment = thisProject.reg_issue_comment>
	<cfset form.reg_msg_view = thisProject.reg_msg_view>
	<cfset form.reg_msg_edit = thisProject.reg_msg_edit>
	<cfset form.reg_msg_comment = thisProject.reg_msg_comment>
	<cfset form.reg_mstone_view = thisProject.reg_mstone_view>
	<cfset form.reg_mstone_edit = thisProject.reg_mstone_edit>
	<cfset form.reg_mstone_comment = thisProject.reg_mstone_comment>
	<cfset form.reg_todolist_view = thisProject.reg_todolist_view>
	<cfset form.reg_todolist_edit = thisProject.reg_todolist_edit>
	<cfset form.reg_todo_edit = thisProject.reg_todo_edit>
	<cfset form.reg_todo_comment = thisProject.reg_todo_comment>
	<cfset form.reg_time_view = thisProject.reg_time_view>
	<cfset form.reg_time_edit = thisProject.reg_time_edit>
	<cfset form.reg_bill_view = thisProject.reg_bill_view>
	<cfset form.reg_bill_edit = thisProject.reg_bill_edit>
	<cfset form.reg_bill_rates = thisProject.reg_bill_rates>
	<cfset form.reg_bill_invoices = thisProject.reg_bill_invoices>
	<cfset form.reg_bill_markpaid = thisProject.reg_bill_markpaid>
	<cfset form.reg_svn = thisProject.reg_svn>
	<cfset form.tab_files = thisProject.tab_files>
	<cfset form.tab_issues = thisProject.tab_issues>
	<cfset form.tab_msgs = thisProject.tab_msgs>
	<cfset form.tab_mstones = thisProject.tab_mstones>
	<cfset form.tab_todos = thisProject.tab_todos>
	<cfset form.tab_time = thisProject.tab_time>
	<cfset form.tab_billing = thisProject.tab_billing>
	<cfset form.tab_svn = thisProject.tab_svn>
	<cfset form.issue_svn_link = thisProject.issue_svn_link>
	<cfset form.issue_timetrack = thisProject.issue_timetrack>
	<cfset form.googlecal = thisProject.googlecal>
	<cfset title_action = "Edit">
	<cfset projectUsers = application.project.projectUsers(url.p)>
	<cfset msgcats = application.message.getCatMsgs(url.p)>
	<cfset filecats = application.file.getCatFiles(url.p)>
	<cfset components = application.project.component(url.p)>
	<cfset versions = application.project.version(url.p)>
<cfelse>
	<cfset form.ownerID = session.user.userID>
	<cfset form.display = 1>
	<cfset form.logo_img = "">
	<cfset form.old_image = "">
	<cfset form.allow_def_rates = 1>
	<cfset form.tab_files = 1>
	<cfset form.tab_issues = 1>
	<cfset form.tab_msgs = 1>
	<cfset form.tab_mstones = 1>
	<cfset form.tab_todos = 1>
	<cfset form.tab_time = 1>
	<cfset form.tab_billing = 1>
	<cfset form.tab_svn = 1>
	<cfset form.issue_svn_link = 1>
	<cfset form.issue_timetrack = 1>
	<cfset projectUsers = application.user.get(activeOnly=true)>
	<cfset newID = createUUID()>
	<cfset form.display = 1>
</cfif>

<cfset clients = application.client.get()>

<!--- Loads header/footer --->
<cfmodule template="#application.settings.mapping#/tags/layout.cfm" templatename="main" title="#application.settings.app_title# &raquo; #title_action# Project" project="#name#" projectid="#projID#" svnurl="#svnurl#">

<cfhtmlhead text="<script type='text/javascript'>
	function confirmSubmit() {
		var errors = '';
		if (document.edit.name.value == '') {errors = errors + '   ** You must enter a name.\n';}
		if (errors != '') {
			alert('Please correct the following errors:\n\n' + errors)
			return false;
		} else return true;
	}
	$(document).ready(function(){
	  	$('##name').focus();
	});
</script>">

<cfoutput>
<div id="container">
	<!--- left column --->
	<div class="left">
		<div class="main">

				<div class="header">
					<span class="rightmenu">
						<a href="javascript:history.back();" class="cancel">Cancel</a>
					</span>
					
					<h2 class="project"><cfif StructKeyExists(url,"p")>Edit<cfelse>Create a new</cfif> project</h2>
				</div>
				<div class="content">
				 	
					<form action="#cgi.script_name#?#cgi.query_string#" method="post" name="edit" id="edit" class="frm pb15" enctype="multipart/form-data" onsubmit="return confirmSubmit();">
						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('general');return false;" class="collapsed" id="generallink"> General Info</a></legend>
							<div id="generalinfo"<cfif StructKeyExists(url,"p")> style="display:none;"</cfif>>
							<p>
							<label for="name" class="req">Name:</label>
							<input type="text" name="name" id="name" value="#HTMLEditFormat(form.name)#" maxlength="50" class="short" />
							</p>					
							<p>
							<label for="description">Description:</label> 
							<cfif session.mobileBrowser>
								<textarea name="description" id="description">#description#</textarea>
							<cfelse>
								<cfscript>
									basePath = 'includes/fckeditor/';
									fckEditor = createObject("component", "#basePath#fckeditor");
									fckEditor.instanceName	= "description";
									fckEditor.value			= '#form.description#';
									fckEditor.basePath		= basePath;
									fckEditor.width			= 390;
									fckEditor.height		= 220;
									fckEditor.ToolbarSet	= "Basic";
									fckEditor.create(); // create the editor.
								</cfscript>&nbsp;
							</cfif>
							<!--->
							<textarea id="description" name="description" rows="15" cols="80" style="width: 80%" class="tinymce">#form.description#</textarea>--->
							</p>
							<p style="font-size:.8em;">
							<label for="display">&nbsp;</label>
							<input type="checkbox" name="display" id="display" value="1" class="checkbox"<cfif form.display> checked="checked"</cfif> /><label for="display" class="wide">Display description on overview page</label>
							</p>
							
							<p>
							<label for="owner">Owner:</label>
							<select name="ownerID" id="owner">
								<cfloop query="projectUsers">
								<option value="#userID#"<cfif not compare(form.ownerID,userID)> selected="selected"</cfif>>#firstName# #lastName#</option>
								</cfloop>
							</select>
							</p>
							
							<p>
							<label for="client">Client:</label>
							<select name="clientID" id="client">
								<option value="" class="i">None</option>
								<cfloop query="clients">
								<option value="#clientID#"<cfif not compare(form.clientID,clientID)> selected="selected"</cfif>>#name#</option>
								</cfloop>
							</select>
							</p>
							
							<p>
							<label for="status">Status:</label>
							<select name="status" id="status">
								<option value="Active"<cfif not compare(form.status,'Active')> selected="selected"</cfif>>Active</option>
								<option value="On-Hold"<cfif not compare(form.status,'On-Hold')> selected="selected"</cfif>>On-Hold</option>
								<option value="Archived"<cfif not compare(form.status,'Archived')> selected="selected"</cfif>>Archived</option>
							</select>
							</p>
							</div>
						</fieldset>

						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('logo');return false;" class="collapsed" id="logolink"> Project Logo</a></legend>
						<div id="logoinfo" style="display:none;">
							<p>
							<label for="imgfile">Logo Image:</label>
							<input type="file" name="imagefile" id="imgfile" />
							</p>				
							<cfif compare(logo_img,'')>
								<p>
								<label for="img">&nbsp;</label>
								<img src="#application.settings.userFilesMapping#/projects/#logo_img#" border="0" alt="#application.settings.company_name#" style="border:1px solid ##666;" />
								<a href="#cgi.script_name#?p=#url.p#&amp;rmvimg">remove</a>
								</p>
							</cfif>
							<p>
							<input type="hidden" name="old_image" value="#old_image#" />
						</div>
						</fieldset>
						
						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('tab');return false;" class="collapsed" id="tablink"> Features Enabled</a></legend>
						<div id="tabinfo" style="display:none;">
						<table class="clean full mb15 permissions">
							<tr>
								<th width="15%">&nbsp;</th>
								<th width="10%">Files</th>
								<th width="10%">Issues</th>
								<th width="10%">Messages</th>
								<th width="10%">Milestones</th>
								<th width="10%">To-Dos</th>
								<th width="15%">Time Tracking</th>
								<th width="10%">Billing</th>
								<th width="10%">SVN</th>
							</tr>
							<tr>
								<td class="b">Feature</td>
								<td><input type="checkbox" name="tab_files" value="1" class="cb"<cfif form.tab_files eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_issues" value="1" class="cb"<cfif form.tab_issues eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_msgs" value="1" class="cb"<cfif form.tab_msgs eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_mstones" value="1" class="cb"<cfif form.tab_mstones eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_todos" value="1" class="cb"<cfif form.tab_todos eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_time" value="1" class="cb"<cfif form.tab_time eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_billing" value="1" class="cb"<cfif form.tab_billing eq 1> checked="checked"</cfif> /></td>
								<td><input type="checkbox" name="tab_svn" value="1" class="cb"<cfif form.tab_svn eq 1> checked="checked"</cfif> /></td>
							</tr>
						</table>
						<label for="def">&nbsp;</label>
						<input type="checkbox" name="allow_def_rates" id="allow_def_rates" value="1" class="checkbox"<cfif form.allow_def_rates> checked="checked"</cfif> />
						<label for="allow_def_rates" class="wide">Enable default billing rates for this project</label>
						</div>
						</fieldset>

						<cfif StructKeyExists(url,"p")>
						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('cat');return false;" class="collapsed" id="catlink"> Category Lists</a></legend>
						<div id="catinfo" style="display:none;">

						<table align="center">
							<tr><td>
								<p>
								<fieldset>
								<legend>File Categories</legend>
									<ul id="filecats">
										<cfif StructKeyExists(url,"p")>
										<cfloop query="filecats">
											<li id="filer#currentRow#">#currentRow#) #category# &nbsp; <a href="##" onclick="$('##filer#currentRow#').hide();$('##edit_filer#currentRow#').show();$('##filecat#currentRow#').focus();return false;">Edit</a> &nbsp;<cfif numFiles><span class="g i">(#numFiles# file<cfif numFiles gt 1>s</cfif>)</span><cfelse><a href="##" onclick="confirm_cat_delete('#url.p#','#categoryID#','#category#','file');return false;" class="delete"></a></cfif></li>
											<li id="edit_filer#currentRow#" style="display:none;">
												<input type="text" id="filecat#currentRow#" value="#category#" class="short" />
												<input type="button" value="Save" onclick="edit_cat('#url.p#','#categoryID#','#currentRow#','file'); return false;" /> or <a href="##" onclick="$('##filer#currentRow#').show();$('##edit_filer#currentRow#').hide();return false;">Cancel</a>
											</li>
										</cfloop>
										</cfif>
									</ul>
									<ul>
										<li id="addnewfile">-- <a href="##" onclick="$('##addnewfile').hide();$('##newrowfile').show();$('##fileCat').focus();return false;">New Category...</a></li>
										<li id="newrowfile" style="display:none;">
											<input type="text" id="fileCat" class="short" />
											<input type="button" value="Add" onclick="add_cat('#url.p#','file'); return false;" /> or <a href="##" onclick="$('##addnewfile').show();$('##newrowfile').hide();return false;">Cancel</a>
										</li>
									</ul>
								</fieldset>
								</p>
							</td><td>&nbsp;&nbsp;&nbsp;</td><td>
								<p>
								<fieldset>
								<legend>Message Categories</legend>
									<ul id="msgcats">
										<cfif StructKeyExists(url,"p")>
										<cfloop query="msgcats">
											<li id="msgr#currentRow#">#currentRow#) #category# &nbsp; <a href="##" onclick="$('##msgr#currentRow#').hide();$('##edit_msgr#currentRow#').show();$('##msgcat#currentRow#').focus();return false;">Edit</a> &nbsp;<cfif numMsgs><span class="g i">(#numMsgs# msgs)</span><cfelse><a href="##" onclick="confirm_cat_delete('#url.p#','#categoryID#','#category#','msg');return false;" class="delete"></a></cfif></li>
											<li id="edit_msgr#currentRow#" style="display:none;">
												<input type="text" id="msgcat#currentRow#" value="#category#" class="short" />
												<input type="button" value="Save" onclick="edit_cat('#url.p#','#categoryID#','#currentRow#','msg'); return false;" /> or <a href="##" onclick="$('##msgr#currentRow#').show();$('##edit_msgr#currentRow#').hide();return false;">Cancel</a>
											</li>
										</cfloop>
										</cfif>
									</ul>
									<ul>
										<li id="addnewmsg">-- <a href="##" onclick="$('##addnewmsg').hide();$('##newrowmsg').show();$('##msgCat').focus();return false;">New Category...</a></li>
										<li id="newrowmsg" style="display:none;">
											<input type="text" id="msgCat" class="short" />
											<input type="button" value="Add" onclick="add_cat('#url.p#','msg'); return false;" /> or <a href="##" onclick="$('##addnewmsg').show();$('##newrowmsg').hide();return false;">Cancel</a>
										</li>
									</ul>
								</fieldset>
								</p>
							</td></tr>
						</table>
						
						</div>
						</fieldset>
						</cfif>

						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('issue');return false;" class="collapsed" id="issuelink"> Issue Details</a></legend>
						<div id="issueinfo" style="display:none;">
						<p>
						<label for="ticketPrefix" class="med">2 Letter Ticket Prefix:</label>
						<input type="text" name="ticketPrefix" id="ticketPrefix" value="#HTMLEditFormat(form.ticketPrefix)#" maxlength="2" style="width:80px" />
						<span class="sma g">(optional two-letter prefix used when generating trouble tickets)</span>
						</p>
						
						<p>
							<label for="issue_svn_link" class="half">Allow linking of SVN Revisions?</label>
							<input type="checkbox" name="issue_svn_link" id="issue_svn_link" class="checkbox" value="1"<cfif form.issue_svn_link eq 1> checked="checked"</cfif> /> <span class="sma g">(may slow things down on remote repositories)</span>
						</p>

						<p>
							<label for="issue_timetrack" class="half">Allow time tracking on issues?</label>
							<input type="checkbox" name="issue_timetrack" id="issue_timetrack" class="checkbox" value="1"<cfif form.issue_timetrack eq 1> checked="checked"</cfif> /> <span class="sma g">(requires time tracking to be enabled under <a href="##" onclick="section_toggle('tab');return false;">features</a>)</span>
						</p>
						
						<cfif StructKeyExists(url,"p")>
						<table align="center">
							<tr><td>
								<p>
								<fieldset>
								<legend>Project Components</legend>
									<ul id="components">
										<cfloop query="components">
											<li id="componentr#currentRow#">#currentRow#) #component# &nbsp; <a href="##" onclick="$('##componentr#currentRow#').hide();$('##edit_componentr#currentRow#').show();$('##component#currentRow#').focus();return false;">Edit</a> &nbsp;<cfif numIssues><span class="g i">(#numIssues# issue<cfif numIssues gt 1>s</cfif>)</span><cfelse><a href="##" onclick="confirm_item_delete('#url.p#','#componentID#','#component#','component');return false;" class="delete"></a></cfif></li>
											<li id="edit_componentr#currentRow#" style="display:none;">
												<input type="text" id="component#currentRow#" value="#component#" class="short" />
												<input type="button" value="Save" onclick="edit_proj_item('#url.p#','#componentID#','#currentRow#','component'); return false;" /> or <a href="##" onclick="$('##componentr#currentRow#').show();$('##edit_componentr#currentRow#').hide();return false;">Cancel</a>
											</li>
										</cfloop>
									</ul>
									<ul>
										<li id="addnewcomponent">-- <a href="##" onclick="$('##addnewcomponent').hide();$('##newrowcomponent').show();$('##newcomponent').focus();return false;">New Component...</a></li>
										<li id="newrowcomponent" style="display:none;">
											<input type="text" id="newcomponent" class="short" />
											<input type="button" value="Add" onclick="add_proj_item('#url.p#','component'); return false;" /> or <a href="##" onclick="$('##addnewcomponent').show();$('##newrowcomponent').hide();return false;">Cancel</a>
										</li>
									</ul>
								</fieldset>
								</p>
							</td><td>&nbsp;&nbsp;&nbsp;</td><td>
								<p>
								<fieldset>
								<legend>Project Versions</legend>
									<ul id="versions">
										<cfloop query="versions">
											<li id="versionr#currentRow#">#currentRow#) #version# &nbsp; <a href="##" onclick="$('##versionr#currentRow#').hide();$('##edit_versionr#currentRow#').show();$('##version#currentRow#').focus();return false;">Edit</a> &nbsp;<cfif numIssues><span class="g i">(#numIssues# issue<cfif numIssues gt 1>s</cfif>)</span><cfelse><a href="##" onclick="confirm_item_delete('#url.p#','#versionID#','#version#','version');return false;" class="delete"></a></cfif></li>
											<li id="edit_versionr#currentRow#" style="display:none;">
												<input type="text" id="version#currentRow#" value="#version#" class="short" />
												<input type="button" value="Save" onclick="edit_proj_item('#url.p#','#versionID#','#currentRow#','version'); return false;" /> or <a href="##" onclick="$('##versionr#currentRow#').show();$('##edit_versionr#currentRow#').hide();return false;">Cancel</a>
											</li>
										</cfloop>
									</ul>
									<ul>
										<li id="addnewversion">-- <a href="##" onclick="$('##addnewversion').hide();$('##newrowversion').show();$('##newversion').focus();return false;">New Version...</a></li>
										<li id="newrowversion" style="display:none;">
											<input type="text" id="newversion" class="short" />
											<input type="button" value="Add" onclick="add_proj_item('#url.p#','version'); return false;" /> or <a href="##" onclick="$('##addnewversion').show();$('##newrowversion').hide();return false;">Cancel</a>
										</li>
									</ul>								
								</fieldset>
								</p>
							</td></tr>
						</table>
						</cfif>
						
						</div>
						</fieldset>
					
						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('svn');return false;" class="collapsed" id="svnlink"> SVN Settings</a></legend>
						<div id="svninfo" style="display:none;">
						<p>
						<label for="svnurl">SVN URL:</label>
						<input type="text" name="svnurl" id="svnurl" value="#HTMLEditFormat(form.svnurl)#" maxlength="100" class="short" />
						</p>						
						<p>
						<label for="svnuser">SVN Username:</label>
						<input type="text" name="svnuser" id="svnuser" value="#HTMLEditFormat(form.svnuser)#" maxlength="20" class="short" />
						</p>						
						<p>
						<label for="svnpass">SVN Password:</label>
						<input type="password" name="svnpass" id="svnpass" value="#HTMLEditFormat(form.svnpass)#" maxlength="20" class="short" />
						</p>
						</div>
						</fieldset>
						
						<cfif application.settings.googlecal_enable>
							<fieldset class="settings">
								<legend><a href="##" onclick="section_toggle('cal');return false;" class="collapsed" id="callink"> Google Calendar</a></legend>
								<div id="calinfo" style="display:none;">
									<p>
									<label for="googlecal">Project Calendar:</label>
									<cfset calendars = application.gCal.getCalendars()>
									<select name="googlecal" id="googlecal">
										<option value=""></option>
										<cfloop query="calendars">
											<option value="#id#"<cfif not compare(form.googlecal,id)> selected="selected"</cfif>>#Title#</option>
										</cfloop>
									</select>
									</p>
								</div>
							</fieldset>
						<cfelse>
							<input type="hidden" name="googlecal" value="#form.googlecal#" />
						</cfif>

						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('sr');return false;" class="collapsed" id="srlink"> Self Registrations</a></legend>
						<div id="srinfo" style="display:none;">
							<p>
							<label for="allowreg" class="full b">Allow users to self-register for this project?</label>
							<input type="checkbox" name="allow_reg" id="allowreg" class="checkbox" value="1"<cfif form.allow_reg eq 1> checked="checked"</cfif> /> (uses default permissions)
							</p>
						</div>
						</fieldset>

						<fieldset class="settings">
						<legend><a href="##" onclick="section_toggle('perms');return false;" class="collapsed" id="permslink"> Default Permissions</a></legend>
						<div id="permsinfo"<cfif not StructKeyExists(url,'showdef')> style="display:none;"</cfif>>
							<table>
							<tr valign="top"><td width="50%">
		
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Messages</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View messages</td>
											<td class="tac"><input type="radio" name="reg_msg_view" value="1"<cfif reg_msg_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_msg_view" value="0"<cfif reg_msg_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Post/edit messages</td>
											<td class="tac"><input type="radio" name="reg_msg_edit" value="1"<cfif reg_msg_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_msg_edit" value="0"<cfif reg_msg_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Comment on messages</td>
											<td class="tac"><input type="radio" name="reg_msg_comment" value="1"<cfif reg_msg_comment eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_msg_comment" value="0"<cfif reg_msg_comment eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>
			
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">To-Dos</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View to-do lists</td>
											<td class="tac"><input type="radio" name="reg_todolist_view" value="1"<cfif reg_todolist_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_todolist_view" value="0"<cfif reg_todolist_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Add/edit to-do lists</td>
											<td class="tac"><input type="radio" name="reg_todolist_edit" value="1"<cfif reg_todolist_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_todolist_edit" value="0"<cfif reg_todolist_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Add/edit to-do items</td>
											<td class="tac"><input type="radio" name="reg_todo_edit" value="1"<cfif reg_todo_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_todo_edit" value="0"<cfif reg_todo_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Comment on to-do items</td>
											<td class="tac"><input type="radio" name="reg_todo_comment" value="1"<cfif reg_todo_comment eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_todo_comment" value="0"<cfif reg_todo_comment eq 0> checked="checked"</cfif> /></td>
										</tr>							
									</tbody>
								</table>
	
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Milestones</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View milestones</td>
											<td class="tac"><input type="radio" name="reg_mstone_view" value="1"<cfif reg_mstone_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_mstone_view" value="0"<cfif reg_mstone_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Add/edit milestones</td>
											<td class="tac"><input type="radio" name="reg_mstone_edit" value="1"<cfif reg_mstone_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_mstone_edit" value="0"<cfif reg_mstone_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Comment on milestones</td>
											<td class="tac"><input type="radio" name="reg_mstone_comment" value="1"<cfif reg_mstone_comment eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_mstone_comment" value="0"<cfif reg_mstone_comment eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>
								
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Files</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View files</td>
											<td class="tac"><input type="radio" name="reg_file_view" value="1"<cfif reg_file_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_file_view" value="0"<cfif reg_file_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Upload/edit files</td>
											<td class="tac"><input type="radio" name="reg_file_edit" value="1"<cfif reg_file_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_file_edit" value="0"<cfif reg_file_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Comment on files</td>
											<td class="tac"><input type="radio" name="reg_file_comment" value="1"<cfif reg_file_comment eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_file_comment" value="0"<cfif reg_file_comment eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>

							</td><td width="50%">
							
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Issues</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View issues</td>
											<td class="tac"><input type="radio" name="reg_issue_view" value="1"<cfif reg_issue_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_issue_view" value="0"<cfif reg_issue_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Add/edit issues</td>
											<td class="tac"><input type="radio" name="reg_issue_edit" value="1"<cfif reg_issue_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_issue_edit" value="0"<cfif reg_issue_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Assign issues</td>
											<td class="tac"><input type="radio" name="reg_issue_assign" value="1"<cfif reg_issue_assign eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_issue_assign" value="0"<cfif reg_issue_assign eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Resolve issues</td>
											<td class="tac"><input type="radio" name="reg_issue_resolve" value="1"<cfif reg_issue_resolve eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_issue_resolve" value="0"<cfif reg_issue_resolve eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Close issues</td>
											<td class="tac"><input type="radio" name="reg_issue_close" value="1"<cfif reg_issue_close eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_issue_close" value="0"<cfif reg_issue_close eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Comment on issues</td>
											<td class="tac"><input type="radio" name="reg_issue_comment" value="1"<cfif reg_issue_comment eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_issue_comment" value="0"<cfif reg_issue_comment eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>
			
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Time Tracking</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View time tracking</td>
											<td class="tac"><input type="radio" name="reg_time_view" value="1"<cfif reg_time_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_time_view" value="0"<cfif reg_time_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Add/edit time tracking</td>
											<td class="tac"><input type="radio" name="reg_time_edit" value="1"<cfif reg_time_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_time_edit" value="0"<cfif reg_time_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>
								
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Billing</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>View billing</td>
											<td class="tac"><input type="radio" name="reg_bill_view" value="1"<cfif reg_bill_view eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_bill_view" value="0"<cfif reg_bill_view eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Add/edit billing</td>
											<td class="tac"><input type="radio" name="reg_bill_edit" value="1"<cfif reg_bill_edit eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_bill_edit" value="0"<cfif reg_bill_edit eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Manage billing rates</td>
											<td class="tac"><input type="radio" name="reg_bill_rates" value="1"<cfif reg_bill_rates eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_bill_rates" value="0"<cfif reg_bill_rates eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Generate invoices</td>
											<td class="tac"><input type="radio" name="reg_bill_invoices" value="1"<cfif reg_bill_invoices eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_bill_invoices" value="0"<cfif reg_bill_invoices eq 0> checked="checked"</cfif> /></td>
										</tr>
										<tr>
											<td>Mark items paid</td>
											<td class="tac"><input type="radio" name="reg_bill_markpaid" value="1"<cfif reg_bill_markpaid eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_bill_markpaid" value="0"<cfif reg_bill_markpaid eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>
								
								<table class="perms def mb10">
									<thead>
										<tr>
											<th class="b">Subversion</th>
											<th class="tac b yes">Yes</th>
											<th class="tac b no">No</th>
										</tr>
									</thead>
									<tbody>
										<tr>
											<td>Access Subversion repository</td>
											<td class="tac"><input type="radio" name="reg_svn" value="1"<cfif reg_svn eq 1> checked="checked"</cfif> /></td>
											<td class="tac"><input type="radio" name="reg_svn" value="0"<cfif reg_svn eq 0> checked="checked"</cfif> /></td>
										</tr>
									</tbody>
								</table>
							</td></tr>
							</table>
						</div>
						</fieldset>	
						
						<label for="submit" class="none">&nbsp;</label>
						<cfif StructKeyExists(url,"p")>
							<input type="submit" class="button" name="submit" id="submit" value="Update Project" />
							<input type="hidden" name="projectID" value="#url.p#" />
						<cfelse>
							<input type="hidden" name="projectID" value="#newID#">
							<input type="submit" class="button" name="submit" id="submit" value="Add Project" />
						</cfif>
						<input type="hidden" name="from" value="#form.from#" />
						<input type="button" class="button" name="cancel" value="Cancel" onclick="history.back();" />
					</form>				 	

				</div>
			
		</div>
		<div class="bottom">&nbsp;</div>
		<div class="footer">
			<cfinclude template="footer.cfm">
		</div>	  
	</div>

	<!--- right column --->
	<div class="right">
		<cfif compare(form.logo_img,'')>
			<img src="#application.settings.userFilesMapping#/projects/#form.logo_img#" border="0" alt="#form.name#" class="projlogo" />
		</cfif>

		<cfif StructKeyExists(url,"p")>
		<div class="header"><h3 class="delete">Delete this project?</h3></div>
		<div class="content">
			Deleting a project immediately and permanently deletes all the messages, milestones, and to-do lists associated with this project. There is no Undo so make sure you're absolutely sure you want to delete this project.<br /><br />

			<a href="#cgi.script_name#?p=#url.p#&amp;ph=#hash(url.p)#&amp;del" class="check" onclick="return confirm('Are you absolutely sure???\nPlease Note: there is no undo.')">Yes, I understand - delete this project</a>
		</div>
		</cfif>

	</div>
</div>
</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly="false">