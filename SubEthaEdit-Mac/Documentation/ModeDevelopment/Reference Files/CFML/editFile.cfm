<cfsetting enablecfoutputonly="true">
<cfprocessingdirective pageencoding="utf-8">

<cfif StructKeyExists(form,"fileID")> <!--- update file --->
	<cfif not compare(form.description,'<br />')>
		<cfset form.description = "">
	</cfif>
	<cfset application.file.update(form.fileID,form.projectid,form.title,form.category,form.description)>
	<cfset application.activity.add(createUUID(),form.projectid,session.user.userid,'File',form.fileID,form.title,'edited')>
	<cfset application.notify.fileUpdate(form.projectid,form.fileID)>
	<cflocation url="files.cfm?p=#form.projectID#" addtoken="false">
<cfelseif StructKeyExists(form,"projectID")> <!--- add/upload file --->
	<cftry>
		<cfdirectory action="create" directory="#application.userFilesPath##form.projectID#">
		<cfcatch></cfcatch>
	</cftry>
	<cffile action="upload" filefield="fileupload" destination = "#application.userFilesPath##form.projectID#" nameConflict = "MakeUnique">
	<cfset newID = createUUID()>
	<cfif not compare(form.description,'<br />')>
		<cfset form.description = "">
	</cfif>
	<cfset application.file.add(newID,form.projectID,form.title,form.category,form.description,cffile.ClientFile,cffile.ServerFile,cffile.ClientFileExt,cffile.FileSize,session.user.userid)>
	<cfset application.activity.add(createUUID(),form.projectid,session.user.userid,'File',newID,form.title,'added')>
	<cfset application.notify.fileNew(form.projectid,newID)>
	<cflocation url="files.cfm?p=#form.projectID#" addtoken="false">
</cfif>

<cfif not StructKeyExists(url,'p')>
	<cfoutput><h2>No Project Selected!</h2></cfoutput><cfabort>
</cfif>

<cfif session.user.admin>
	<cfset project = application.project.get(projectID=url.p)>
<cfelse>
	<cfset project = application.project.get(session.user.userid,url.p)>
</cfif>
<cfset categories = application.category.get(url.p,'file')>

<cfif not session.user.admin and not project.file_edit eq 1>
	<cfoutput><h2>You do not have permission to <cfif StructKeyExists(url,"f")>edit<cfelse>add</cfif> files!!!</h2></cfoutput>
	<cfabort>
</cfif>

<cfparam name="fileupload" default="">
<cfparam name="title" default="">
<cfparam name="catID" default="">
<cfparam name="description" default="">
<cfparam name="title_action" default="Add">

<cfif StructKeyExists(url,"f")>
	<cfset thisFile = application.file.get(url.p,url.f)>
	<cfset title = thisFile.title>
	<cfset catID = thisFile.categoryID>
	<cfset description = thisFile.description>
	<cfset title_action = "Edit">
</cfif>

<!--- Loads header/footer --->
<cfmodule template="#application.settings.mapping#/tags/layout.cfm" templatename="main" title="#project.name# &raquo; #title_action# File" project="#project.name#" projectid="#url.p#" svnurl="#project.svnurl#">

<cfhtmlhead text="<script type='text/javascript'>
	function newFileCat(val) {
		if (val == 'new') {
			var newcat = prompt('Enter the new category name:','');
			var opt = new Option(newcat, newcat);
	  		var sel = document.edit.category;
	  		sel.options[sel.options.length] = opt;
			sel.selectedIndex = sel.options.length-1;		
		}	
	}
	function confirmSubmit() {
		var errors = '';
		var oEditor = FCKeditorAPI.GetInstance('description');
		if (document.edit.title.value == '') {errors = errors + '   ** You must enter a title.\n';}
		if (document.edit.category.value == '') {errors = errors + '   ** You must select a category.\n';}
		if (oEditor.GetHTML() == '') {errors = errors + '   ** You must enter a description.\n';}
		if (errors != '') {
			alert('Please correct the following errors:\n\n' + errors)
			return false;
		} else return true;
	}
	$(document).ready(function(){
	  	$('##title').focus();
	});	
</script>">

<cfoutput>
<div id="container">
<cfif project.recordCount>
	<!--- left column --->
	<div class="left">
		<div class="main">

				<div class="header">
					<span class="rightmenu">
						<a href="javascript:history.back();" class="cancel">Cancel</a>
					</span>
					
					<h2 class="msg"><cfif StructKeyExists(url,"m")>Edit<cfelse>Upload new</cfif> file</h2>
				</div>
				<div class="content">
				 	
					<form action="#cgi.script_name#?#cgi.query_string#" method="post" name="edit" id="edit" class="frm pb15" enctype="multipart/form-data" onsubmit="return confirmSubmit();">
						<cfif not StructKeyExists(url,"f")>
						<p>
						<label for="fileupload" class="req">File:</label>
						<input type="file" name="fileupload" id="fileupload" value="#fileupload#" />
						</p>
						</cfif>
						<p>
						<label for="title" class="req">Title:</label>
						<input type="text" name="title" id="title" value="#HTMLEditFormat(title)#" maxlength="120" />
						</p>
						<p>
						<label for="category" class="req">Category:</label>
						<select name="category" id="category" onChange="newFileCat(this.value);">
							<option value="">Select Category...</option>
							<cfloop query="categories">
							<option value="#categoryID#"<cfif not compare(catID,categoryID)> selected="selected"</cfif>>#category#</option>
							</cfloop>
							<option value="new">--- add new category ---</option>
						</select>
						</p>											
						<p>
						<label for="description" class="req">Description:</label> 
						<cfif session.mobileBrowser>
							<textarea name="description" id="description">#description#</textarea>
						<cfelse>
							<cfscript>
								basePath = 'includes/fckeditor/';
								fckEditor = createObject("component", "#basePath#fckeditor");
								fckEditor.instanceName	= "description";
								fckEditor.value			= '#description#';
								fckEditor.basePath		= basePath;
								fckEditor.width			= 460;
								fckEditor.height		= 150;
								fckEditor.ToolbarSet	= "Basic";
								fckEditor.create(); // create the editor.
							</cfscript>&nbsp;
						</cfif>
						</p>		
						<label for="submit">&nbsp;</label>
						<cfif StructKeyExists(url,"f")>
							<input type="submit" class="button" name="submit" id="submit" value="Update File" onclick="return confirmSubmit();" />
							<input type="hidden" name="fileID" value="#url.f#" />
						<cfelse>
							<input type="submit" class="button" name="submit" id="submit" value="Upload File" />
						</cfif>
						<input type="button" class="button" name="cancel" value="Cancel" onclick="history.back();" />
						<input type="hidden" name="projectID" value="#url.p#" />
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
	<!---
		<div class="textheader"><h3>Categories</h3></div>
		<div class="content">
			<ul>
			</ul>
		</div>
	--->	
	</div>
<cfelse>
	<div class="alert">Project Not Found.</div>
</cfif>
</div>
</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly="false">