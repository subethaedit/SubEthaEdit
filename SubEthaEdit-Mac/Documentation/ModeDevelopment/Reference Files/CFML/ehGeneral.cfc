<cfcomponent extends="ehColdBricks">

	<cffunction name="onApplicationStart" access="public" returntype="void">
		<cfset var errors = 0>
		
		<cftry>
			<!--- setup data directory (if needed for xml data storage) --->
			<cfset checkDataRoot()>
					
			<cfcatch type="any">
				<cfset request.errorStep = "Setting up and verifying data directory">
				<cfset request.fatal = true>
				<cfset request.error = cfcatch>
				<cfinclude template="../views/vwInitError.cfm">
				<cfabort>
			</cfcatch>
		</cftry>

		<cftry>
			<!--- initialize modules --->
			<cfset errors = initModules()>

			<cfif arrayLen(errors) gt 0>
				<cfset request.errorStep = "Initializing and loading modules">
				<cfset request.fatal = false>
				<cfset request.moduleInitErrors = errors>
				<cfinclude template="../views/vwInitError.cfm">
				<cfabort>
			</cfif>

			<cfcatch type="any">
				<cfset request.errorStep = "Initializing and loading modules">
				<cfset request.fatal = true>
				<cfset request.error = cfcatch>
				<cfinclude template="../views/vwInitError.cfm">
				<cfabort>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="onRequestStart" access="public" returntype="void">
		<!--- code to execute at the beginning of each request --->
		<cfscript>
			var appTitle = getSetting("applicationTitle", application.applicationName);
			var event = getEvent();
			var hostName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
			var versionTag = getSetting("versionTag");
			var lstFreeEvents = "ehGeneral.doLogin,ehGeneral.dspLogin,ehGeneral.doRegister,ehGeneral.dspRegister";
			var firstRunDate = "";
			var ls = "";
			var isAllowed = true;
			var oUser = 0;
			var oContext = getService("sessionContext").getContext();
		
			// get user object in session (if exists)
			if(oContext.hasUser())
				oUser = oContext.getUser();
			else {
				oUser = createObject("component","ColdBricks.components.model.userBean").init();
				oContext.setUser(oUser);
			}
			
			try {
				// check for data directory
				checkDataRoot();
				
			} catch(any e) {
				writeOutput("Fatal Error. Cannot continue: " & e.message);
				getService("bugTracker").notifyService(e.message, e);
				abort();
			}
				
			try {
				// if the request is for an external module, then drop the external module prefix 
				if(listLen(event,".") gt 3) event = listDeleteAt(event,1,".");
				
				// check login
				if(not listFindNoCase(lstFreeEvents,event) and (oUser.getID() eq 0 or oUser.getID() eq "")) {
					setMessage("Warning","Please enter your username and password");
					setNextEvent("ehGeneral.dspLogin");
				}
	
				// check authorization
				isAllowed = getService("permissions").isAllowed(event, oUser.getRole());
				if(not isAllowed) {
					setMessage("Warning","The requested action is restricted. [#event#]");
					
					// check if we can send the user to the admin dashboard page
					// if not, then send them to the login page
					if(getService("permissions").isAllowed( getSetting("homeEvent") , oUser.getRole())) {
						setNextEvent( getSetting("homeEvent") );
					} else {
						setNextEvent("ehGeneral.dspLogin");
					}
				}

				// set module path
				if(getValue("_isexternalmodule_"))
					setValue("cbModulesPath", getSetting("externalModulesRoot"));
				else
					setValue("cbModulesPath","/ColdBricks/modules");
		
				// set generally available values on the request context
				setValue("hostName", hostName);
				setValue("applicationTitle", appTitle);
				setValue("versionTag", versionTag);
	
				setValue("oUser", oUser);
				setValue("oContext", oContext);
	
				// these are values that can be used to modify the layout
				setValue("cbPageTitle", "");
				setValue("cbPageIcon", "");
				setValue("cbShowSiteMenu", false);
	
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
			}
		</cfscript>
	</cffunction>

	<cffunction name="onRequestEnd" access="public" returntype="void">
	</cffunction>

	<cffunction name="dspLogin" access="public" returntype="void">
		<cfscript>
			setView("vwLogin");
			setLayout("layout.clean");
		</cfscript>
	</cffunction>

	<cffunction name="dspMain" access="public" returntype="void">
		<cfset setNextEvent( getSetting("homeEvent") )>
	</cffunction>

	<cffunction name="dspChangePassword" access="public" returntype="void">
		<cfset setValue("cbPageTitle", "Change Password")>
		<cfset setView("vwChangePassword")>
	</cffunction>
	
	<cffunction name="doLogin" access="public" returntype="void">
		<cfset var usr = getValue("usr")>
		<cfset var pwd = getValue("pwd")>
		<cfset var oUserDAO = 0>
		<cfset var oUser = 0>
		<cfset var oContext = 0>
		<cfset var stAccessMap = structNew()>
		<cfset var qryRoles = queryNew("")>
		<Cfset var i = 0>
	
		<cfscript>
			try {
				oUserDAO = getService("DAOFactory").getDAO("user");
	
				qry = oUserDAO.search(username = usr, password = pwd);
	
				if(qry.recordCount eq 0) 
					throw("Invalid username/password","coldBricks.validation");
				else {
					// build user bean
					oUser = createObject("component","ColdBricks.components.model.userBean").init();
					oUser.setID(qry.userID);
					oUser.setFirstName(qry.firstName);
					oUser.setLastName(qry.lastName);
					oUser.setUsername(qry.username);
					oUser.setPassword(qry.password);
					oUser.setEmail(qry.email);
					oUser.setRole(qry.role);
					oUser.setRoleLabel(qry.role);
					oUser.setIsAdministrator(qry.role eq "admin");
					
					// build access map
					stAccessMap = getService("permissions").buildAccessMap(qry.role);
					oUser.setAccessMap(stAccessMap);
					
					// get role label
					qryRoles = getService("permissions").getRoles();
					for(i=1;i lte qryRoles.recordCount;i=i+1) {
						if(qryRoles.name[i] eq qry.role) {
							oUser.setRoleLabel(qryRoles.label[i]);
							break;
						}
					}
					
					oContext = getService("sessionContext").getContext();
					oContext.setUser(oUser);
				}
	
				setNextEvent("ehGeneral.dspMain");
			
			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("ehGeneral.dspLogin");
	
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("ehGeneral.dspLogin");
			}			
		</cfscript>
	</cffunction>

	<cffunction name="doLogoff" access="public" returntype="void">
		<cfset getService("sessionContext").flushContext()>
		<cfset structClear(session)>
		<cfset setNextEvent("ehGeneral.dspMain")>
	</cffunction>

	<cffunction name="doChangePassword" access="public" returntype="void">
		<cfscript>
			var oUserDAO = 0;
			var oUser = getValue("oUser");
			var curr_pwd = getValue("curr_pwd","");
			var new_pwd = getValue("new_pwd","");
			var new_pwd2 = getValue("new_pwd2","");
			
			try {
				oUserDAO = getService("DAOFactory").getDAO("user");
				
				// validate record
				if(curr_pwd neq oUser.getPassword()) throw("Invalid password","coldBricks.validation");
				if(new_pwd neq new_pwd2) throw("Password confirmation did not match","coldBricks.validation");
				if(len(new_pwd) lt 5) throw("Password must be at least 5 characters long","coldBricks.validation");
				
				// save record
				oUserDAO.save(id = oUser.getID(),
								password = new_pwd
								);
								
				// update current user obj in memory
				oUser.setPassword(new_pwd);
				
				getService("sessionContext").getContext().setUser( oUser );
	
				setMessage("info","Your password has been changed. You must log-in again for changes to take effect");
			
			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("ehGeneral.dspChangePassword");
	
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("ehGeneral.dspChangePassword");
			}
	
			setNextEvent("ehGeneral.dspMain");
		</cfscript>				
	</cffunction>

	<cffunction name="setupDataDirectory" access="private" returntype="void">
		<cfargument name="dataRoot" type="string" required="true">
		<cfargument name="deleteExisting" type="boolean" required="false" default="false" hint="indicates whether to delete the data root dir in case it already exists">
	
		<cfset var tmpFile = "">
		<cfset var pathSeparator =  createObject("java","java.lang.System").getProperty("file.separator")>
		
		<!--- check for invalid names --->
		<cfif listFindNoCase("/,/homePortals,/ColdBricks",arguments.dataRoot) or arguments.dataRoot eq "">
			<cfthrow message="The dataRoot property is invalid." type="ColdBricks.setup.invalidDataRoot">
		</cfif>
		
		<!--- check if we want to delete the existing directory --->
		<cfif arguments.deleteExisting and directoryExists(expandPath(arguments.dataRoot))>
			<cfdirectory action="delete" directory="#expandPath(arguments.dataRoot)#" recurse="true">
		</cfif>
		
		<cfif not directoryExists(expandPath(arguments.dataRoot))>
			<!--- create data directory --->
			<cfdirectory action="create" directory="#expandPath(arguments.dataRoot)#">
			
			<!--- add application.cfm file to block direct access --->
			<cfset tmpFile = expandPath(arguments.dataRoot) & pathSeparator & "Application.cfm">
			<cffile action="write" file="#tmpFile#" output="<cfabort>">
					
			<!--- initialize data files --->
			<cfinclude template="/ColdBricks/includes/initData.cfm">
		</cfif>
	</cffunction>

	<cffunction name="checkDataRoot" access="private" returntype="void">
		<cfscript>
			var dataRoot = getSetting("dataRoot");
			
			if(not directoryExists(expandPath(dataRoot))) {
				setupDataDirectory(dataRoot);
				redirect("index.cfm");
			}
		</cfscript>
	</cffunction>

	<cffunction name="reinstall" access="private" returntype="void">
		<cfset var dataRoot = getSetting("dataRoot")>
		<cfset setupDataDirectory(dataRoot, true)>
		<cfset redirect("index.cfm")>
	</cffunction>

	<cffunction name="initModules" access="private" returntype="array">
		<cfset var qryDir = 0>
		<cfset var lstModulesPath = listAppend("/ColdBricks/modules", getSetting("externalModulesRoot"))>
		<cfset var modulesPath = "">
		<cfset var tmp = "">
		<cfset var st = structNew()>
		<cfset var aInitErrors = arrayNew(1)>
		
		<cfloop list="#lstModulesPath#" index="modulesPath">
			<cfif directoryExists(expandPath(modulesPath))>
				<!--- get existing modules --->
				<cfdirectory action="list" directory="#expandPath(modulesPath)#" name="qryDir">
		
				<!--- get only directories, and filter out special purpose dirs --->
				<cfquery name="qryDir" dbtype="query">
					SELECT *
						FROM qryDir
						WHERE upper(type) = 'DIR'
							AND Name NOT LIKE '.%'
						ORDER BY Name
				</cfquery>	
				
				<cfloop query="qryDir">
					<!--- build path of plugin manifest file --->
					<cfset tmp = modulesPath & "/" & qryDir.name & "/init.cfm">
					<cfif fileExists(expandPath(tmp))>
						<cftry>
							<cfinclude template="#tmp#">
							<cfcatch type="any">
								<cfset st = { name = qryDir.name,
											  message = cfcatch.message }>
								<cfset arrayAppend(aInitErrors, st)>
							</cfcatch>
						</cftry>
					</cfif>
				</cfloop>	
			</cfif>
		</cfloop>
		
		<cfreturn aInitErrors>
	</cffunction>

</cfcomponent>