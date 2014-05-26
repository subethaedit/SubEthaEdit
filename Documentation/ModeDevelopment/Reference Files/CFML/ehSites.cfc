<cfcomponent extends="ColdBricks.handlers.ehColdBricks">

	<cffunction name="dspHome" access="public" returntype="void">
		<cfscript>
			var oSiteDAO = 0;
			var oUserDAO = 0;
			var qrySites = 0;
			var oUser = getValue("oUser");
			var aModules = arrayNew(1);
	
			try {
				// clear site from context (releases memory allocated to the site context)
				getService("sessionContext").getContext().clearSiteContext();
				
				// if this is a regular user then go to sites screen
				if(not oUser.getIsAdministrator()) 	setNextEvent("sites.ehSites.dspMain");
	
				oSiteDAO = getService("DAOFactory").getDAO("site");
				oUserSiteDAO = getService("DAOFactory").getDAO("userSite");
				
				qrySites = oSiteDAO.getAll();
				qryUserSites = oUserSiteDAO.search(userID = oUser.getID());
	
				// get features
				aModules = getService("UIManager").getServerFeatures();

				// get widgets
				stWidgets = renderWidgets( getService("UIManager").getServerWidgets() );
				
				setValue("qrySites",qrySites);
				setValue("qryUserSites",qryUserSites);
				setValue("aModules",aModules);
				setValue("stWidgets",stWidgets);
				setValue("showHomePortalsAsSite", getSetting("showHomePortalsAsSite"));
				setValue("cbPageTitle", "Administration Dashboard");
				setView("vwHome");
			
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setView("");
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="dspMain" access="public" returntype="void">
		<cfscript>
			var oSiteDAO = 0;
			var oUserDAO = 0;
			var qrySites = 0;
			var oUser = getValue("oUser");
			
			try {
				oSiteDAO = getService("DAOFactory").getDAO("site");
				oUserSiteDAO = getService("DAOFactory").getDAO("userSite");
				
				qrySites = oSiteDAO.getAll();
				qryUserSites = oUserSiteDAO.search(userID = oUser.getID());

				// if this is a regular user that has only one site, then 
				// go directly to that site
				if(not oUser.getIsAdministrator() and qryUserSites.recordCount eq 1)
					setNextEvent("sites.ehSite.doLoadSite","siteID=#qryUserSites.siteID#");

				setValue("qrySites",qrySites);
				setValue("qryUserSites",qryUserSites);
				setValue("showHomePortalsAsSite", getSetting("showHomePortalsAsSite"));
				setValue("cbPageTitle", "Site Management");
				setValue("cbPageIcon", "images/folder_desktop_48x48.png");
				setView("vwMain");
			
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
			}
		</cfscript>	
	</cffunction>

	<cffunction name="dspCreate" access="public" returntype="void">
		<cfset var siteTemplatesRoot = getSetting("siteTemplatesRoot")>
		<cfset var siteTemplate = getValue("siteTemplate")>
		<cfset var name = getValue("name")>
		<cfset var appRoot = getValue("appRoot")>
		
		<cfscript>
			// get registered site templates
			aSites = getService("siteTemplates").getSiteTemplates();
			
			// get default values for site name and path
			if(siteTemplate neq "" and name eq "") {
				keepLooping = true;
				index = 1;
				name = replaceNoCase(siteTemplate," ","","ALL");
				oSiteDAO = getService("DAOFactory").getDAO("site");
				checkName = name;
				
				while(keepLooping and index lt 100) {
					qry = oSiteDAO.search(siteName = checkName);
					keepLooping = (qry.recordCount gt 0); 
					if(keepLooping) checkName = name & index;
					index = index + 1; 
				}
				name = checkName;
				appRoot = "/" & checkName;
			}
			
			setValue("aSites", aSites);
			setValue("name", name);
			setValue("appRoot", appRoot);
			setValue("siteTemplatesRoot", siteTemplatesRoot);
			setValue("cbPageTitle", "Site Management > Create New Site");
			setValue("cbPageIcon", "images/folder_desktop_48x48.png");
			setView("vwCreate");
		</cfscript>
	</cffunction>

	<cffunction name="dspCreateCustom" access="public" returntype="void">
		<cfscript>
			setValue("cbPageTitle", "Site Management > Create Custom Site");
			setValue("cbPageIcon", "images/folder_desktop_48x48.png");
			setView("vwCreateCustom");
		</cfscript>
	</cffunction>

	<cffunction name="dspDelete" access="public" returntype="void">
		<cfscript>
			var siteID = getValue("siteID");
			var oSiteDAO = 0;
			var qrySite = 0;
			var allowDeleteFiles = true;
			
			try {			
				// get site information
				oSiteDAO = getService("DAOFactory").getDAO("site");
				qrySite = oSiteDAO.get(siteID);

				if(qrySite.path eq "/") {
					allowDeleteFiles = false;
					setMessage("warning","You cannot delete files from sites located at root level. They can only be unregistered from ColdBricks.");
				}

				setValue("qrySite",qrySite);
				setValue("allowDeleteFiles",allowDeleteFiles);
				setValue("cbPageTitle", "Site Management > Confirm Site Deletion");
				setValue("cbPageIcon", "images/folder_desktop_48x48.png");
				setView("vwDelete");

			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("sites.ehSites.dspMain");
				
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("sites.ehSites.dspMain");
			}
		</cfscript>
	</cffunction>

	<cffunction name="dspRegister" access="public" returntype="void">
		<cfset setValue("cbPageTitle", "Site Management > Register Existing Site")>
		<cfset setValue("cbPageIcon", "images/folder_desktop_48x48.png")>
		<cfset setView("vwRegister")>
	</cffunction>

	<cffunction name="dspEditXML" access="public" returntype="void">
		<cfscript>
			var xmlDocStr = "";
			var oFormatter = createObject("component","ColdBricks.components.xmlStringFormatter").init();
			var hpConfigPath = getSetting("homePortalsConfigPath");
			var siteID = getValue("siteID");
			var xmlContent = getValue("xmlContent");
			var errorMessage = "";
			var oConfig = 0;
			
			try {
				// get site information
				oSiteDAO = getService("DAOFactory").getDAO("site");
				qrySite = oSiteDAO.get(siteID);

				configFile = qrySite.path & getSetting("homePortalsConfigPath");

				if(xmlContent eq "") {
					if(fileExists(expandPath(configFile))) {
						try {
							xmlDoc = xmlParse(expandPath(configFile));
						} catch(any e) {
							errorMessage = e.message;
						}
					} else {
						errorMessage = "Config file does not exist";
					}
				} else {
					xmlDoc = xmlContent;
					try {
						xmlDoc = xmlParse(xmlDoc);
					} catch(any e) {
						errorMessage = e.message;
					}
				}

				if(errorMessage eq "") {
					if(isXMLDoc(xmlDoc)) {
						xmlDocStr = oFormatter.makePretty(xmlDoc.xmlRoot);
					} else {
						errorMessage = "The given content is not a valid XML document";
					}
				}

				if(errorMessage eq "") {
					try {
						oConfig = createObject("component","homePortals.components.homePortalsConfigBean").init().loadXML(xmlDoc);
					} catch(any e) {
						errorMessage = "The given content is not a valid config file. #e.message#";
					}
				}

				setView("vwEditXML");
				setValue("xmlContent", xmlDocStr);
				setValue("errorMessage", errorMessage);
				setValue("siteID", siteID);
				setValue("configFile", configFile);
				setValue("cbPageTitle", "Site Management > Repair Site Config");
				setValue("cbPageIcon", "images/configure_48x48.png");
				
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("sites.ehSites.dspMain");			
			}
		</cfscript>		
	</cffunction>

	<cffunction name="dspHomePortalsCheck" access="public" returntype="void">
		<cfscript>
			var oHomePortals = 0;
			
			setLayout("Layout.None");
			
			try {
				// check existence of homeportals engine
				oHomePortals = createObject("Component","homePortals.components.homePortals").init("/homePortals");
				
				setValue("hpVersion", oHomePortals.getConfig().getVersion());
					
				setView("vwHomePortalsCheck");		

			} catch(any e) {
				setValue("errorInfo",e);
				setView("vwHomePortalsCheckError");		
			}
		</cfscript>
	</cffunction>

	<cffunction name="doCreate" access="public" returntype="void">
		<cfscript>
			var name = getValue("name");
			var appRoot = getValue("appRoot");
			var contentRoot = getValue("contentRoot");
			var resourcesRoot = getValue("resourcesRoot");
			var oUser = getValue("oUser");
			var deployToWebRoot = getValue("deployToWebRoot",false);
			var siteTemplate = getValue("siteTemplate");
			var accountsRoot = "accounts";
			
			var siteTemplatePath = getSetting("siteTemplatesRoot");
			
			var oSiteDAO = 0;
			var qrySiteCheck = 0;
			var siteID = 0;
			
			try {
				if(isBoolean(deployToWebRoot) and deployToWebRoot) appRoot = "/";
				if(name eq "") throw("Site name cannot be empty","coldBricks.validation");
				if(appRoot eq "") throw("Application root cannot be empty","coldBricks.validation");
				if(siteTemplate eq "") throw("Please select a site template","coldBricks.validation");

				// check that application root and name only contains valid characters
				if(reFind("[^A-Za-z0-9_\ ]",name)) throw("The site name can only contain characters from the alphabet, digits, the underscore symbol and the space","coldbricks.validation");
				if(reFind("[^A-Za-z0-9_/\-]",appRoot)) throw("The application root can only contain characters from the alphabet, digits, the underscore symbol and the backslash","coldbricks.validation");

				// make sure the approot doesnt exist already
				if(appRoot neq "/" and directoryExists(expandPath(appRoot))) 
					throw("The given application directory already exists. Please select a different directory","coldBricks.validation");
				
				// check that the directory is not a restricted one
				if(left(appRoot,6) eq "/homePortals/" 
					or appRoot eq "/homePortals"
					or left(appRoot,11) eq "/ColdBricks") {
					throw("You are trying to use a restricted directory as the application root. Please select a different application root.","coldBricks.validation");
				}

				// make sure application root path start and end with / for consistency and to avoid problems later
				if(left(appRoot,1) neq "/") throw("All paths must be relative to the website root and start with '/'","coldBricks.validation");
				if(right(appRoot,1) neq "/") appRoot = appRoot & "/";
				
				// check if site is already registered in coldbricks
				oSiteDAO = getService("DAOFactory").getDAO("site");
				qrySiteCheck = oSiteDAO.search(siteName = name);
				if(qrySiteCheck.recordCount gt 0) 
					throw("There is already another site registered with the name '#name#', please select a different site name.","coldBricks.validation");

				// check if there is another site pointing to this path
				qrySiteCheck = oSiteDAO.search(path = appRoot);
				if(qrySiteCheck.recordCount gt 0) 
					throw("There is already another site pointing to the same directory '#appRoot#', please select a different application root.","coldBricks.validation");

				resourcesRoot = appRoot & "resourceLibrary/";
				contentRoot = appRoot & "content/";
				
				srcAppRoot = siteTemplatePath & "/" & siteTemplate & "/appRoot";
				srcResRoot = siteTemplatePath & "/" & siteTemplate & "/resourcesRoot";
				srcContentRoot = siteTemplatePath & "/" & siteTemplate & "/contentRoot";

				// copy application skeletons
				directoryCopy(expandPath(srcAppRoot), expandPath(appRoot));

				if(directoryExists(expandPath(srcResRoot))) {
					directoryCopy(expandPath(srcResRoot), expandPath(resourcesRoot));
				}
				if(directoryExists(expandPath(srcContentRoot))) {
					directoryCopy(expandPath(srcContentRoot), expandPath(contentRoot));
				}
				
				// replace tokens on copied files
				replaceTokens(appRoot & "/Application.cfc", name, appRoot, accountsRoot, resourcesRoot, contentRoot);
				
				// process all files in the config directory for Tokens
				qryDir = listDir(expandPath(appRoot & "/config"));
				for(i=1;i lte qryDir.recordCount;i=i+1) {
					if(qryDir.type[i] eq "file") {
						replaceTokens(appRoot & "/config/" & qryDir.name[i], name, appRoot, accountsRoot, resourcesRoot, contentRoot);
					}
				}

				// create site record for coldbricks
				siteID = oSiteDAO.save(id=0, siteName=name, path=appRoot, ownerUserID=oUser.getID(), createdDate=dateFormat(now(),"mm/dd/yyyy"), notes="");

				setMessage("info", "The new site has been created.");

				setNextEvent("sites.ehSites.dspHome","loadSiteID=#siteID#");

			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("sites.ehSites.dspCreate","appRoot=#appRoot#&name=#name#&siteTemplate=#siteTemplate#");
			
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("sites.ehSites.dspCreate","appRoot=#appRoot#&name=#name#&siteTemplate=#siteTemplate#");
			}
		</cfscript>
	</cffunction>

	<cffunction name="doCreateCustom" access="public" returntype="void">
		<cfscript>
			var name = getValue("name");
			var appRoot = getValue("appRoot");
			var contentRoot = getValue("contentRoot");
			var resourcesRoot = getValue("resourcesRoot");
			var useDefault_rl = getValue("useDefault_rl",0);
			var oUser = getValue("oUser");
			var deployToWebRoot = getValue("deployToWebRoot",false);
			var bCreateResourceDir = false;
			var bCreateContentDir = false;
			var oSiteDAO = 0;
			var qrySiteCheck = 0;
			var siteID = 0;
			var crlf = chr(10) & chr(13);
			
			try {
				if(isBoolean(deployToWebRoot) and deployToWebRoot) appRoot = "/";
				if(name eq "") throw("Site name cannot be empty","coldBricks.validation");
				if(appRoot eq "") throw("Application root cannot be empty","coldBricks.validation");
	
				// check that application root and name only contains valid characters
				if(reFind("[^A-Za-z0-9_\ ]",name)) throw("The site name can only contain characters from the alphabet, digits, the underscore symbol and the space","coldbricks.validation");
				if(reFind("[^A-Za-z0-9_/\-]",appRoot)) throw("The application root can only contain characters from the alphabet, digits, the underscore symbol and the backslash","coldbricks.validation");

				// make sure the approot doesnt exist already
				if(appRoot neq "/" and directoryExists(expandPath(appRoot))) 
					throw("The given application directory already exists. Please select a different directory","coldBricks.validation");
				
				// check that the directory is not a restricted one
				if(left(appRoot,6) eq "/homePortals/" 
					or appRoot eq "/homePortals"
					or left(appRoot,11) eq "/ColdBricks") {
					throw("You are trying to use a restricted directory as the application root. Please select a different application root.","coldBricks.validation");
				}

				// make sure application root path start and end with / for consistency and to avoid problems later
				if(left(appRoot,1) neq "/") throw("All paths must be relative to the website root and start with '/'","coldBricks.validation");
				if(right(appRoot,1) neq "/") appRoot = appRoot & "/";
				
				// check if site is already registered in coldbricks
				oSiteDAO = getService("DAOFactory").getDAO("site");
				qrySiteCheck = oSiteDAO.search(siteName = name);
				if(qrySiteCheck.recordCount gt 0) 
					throw("There is already another site registered with the name '#name#', please select a different site name.","coldBricks.validation");

				// check if there is another site pointing to this path
				qrySiteCheck = oSiteDAO.search(path = appRoot);
				if(qrySiteCheck.recordCount gt 0) 
					throw("There is already another site pointing to the same directory '#appRoot#', please select a different application root.","coldBricks.validation");


				// create custom site
				if(contentRoot eq "") throw("Content root cannot be empty","coldBricks.validation");
				if(reFind("[^A-Za-z0-9_/\-]",contentRoot)) throw("The content root can only contain characters from the alphabet, digits, the underscore symbol and the backslash","coldbricks.validation");
				if(useDefault_rl eq 1 and resourcesRoot eq "") throw("Resource Library root cannot be empty","coldBricks.validation");
				if(useDefault_rl eq 0) resourcesRoot = "";

				// check if we need to create the resources root
				if(useDefault_rl eq 1 and not directoryExists(expandPath(resourcesRoot))) {
					bCreateResourceDir = true;
				}

				if(useDefault_rl eq 1) {
					if(left(resourcesRoot,1) neq "/") throw("All paths must be relative to the website root and start with '/'","coldBricks.validation");
					if(right(resourcesRoot,1) neq "/") resourcesRoot = resourcesRoot & "/";
				}
				
				// check if we need to create the content root
				if(left(contentRoot,1) neq "/") throw("All paths must be relative to the website root and start with '/'","coldBricks.validation");
				if(right(contentRoot,1) neq "/") contentRoot = contentRoot & "/";
				bCreateContentDir = (not directoryExists(expandPath(contentRoot))); 
				
				// create app directory structure
				if(appRoot neq "/") createDir(expandPath(appRoot));
				createDir(expandPath(appRoot & "/config"));
				if(bCreateContentDir) createDir(expandPath(contentRoot));
				if(bCreateResourceDir) createDir(expandPath(resourcesRoot));
					
				// create config
				oConfigBean = createObject("component","homePortals.components.homePortalsConfigBean").init();
				oConfigBean.setAppRoot(appRoot);
				oConfigBean.setContentRoot(contentRoot);
				oConfigBean.setDefaultPage("default");
				if(resourcesRoot neq "") oConfigBean.addResourceLibraryPath(resourcesRoot);
				getService("configManager").saveHomePortalsConfigDoc(appRoot, oConfigBean.toXML());
				
				// create Application.cfc
				txt = fileRead(expandPath("/ColdBricks/modules/sites/files/Application.cfc.txt"));
				txt = replace(txt, "$APP_NAME$", name, "ALL");
				txt = replace(txt, "$APP_ROOT$", appRoot, "ALL");
				fileWrite(expandPath(appRoot & "Application.cfc"), txt, "utf-8");
				
				// create index.cfm
				txt = fileRead(expandPath("/ColdBricks/modules/sites/files/index.cfm.txt"));
				fileWrite(expandPath(appRoot & "index.cfm"), txt, "utf-8");

				// create default.xml
				if(not fileExists(expandPath(contentRoot & "default.xml"))) {
					txt = fileRead(expandPath("/ColdBricks/modules/sites/files/default.xml.txt"));
					fileWrite(expandPath(contentRoot & "default.xml"), txt, "utf-8");
				}

				// create site record for coldbricks
				siteID = oSiteDAO.save(id=0, 
										siteName=name, 
										path=appRoot, 
										ownerUserID=oUser.getID(), 
										createdDate=dateFormat(now(),"mm/dd/yyyy"), 
										notes="");

				setMessage("info", "The new site has been created.");

				setNextEvent("sites.ehSites.dspHome","loadSiteID=#siteID#");

			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("sites.ehSites.dspCreateCustom","appRoot=#appRoot#&name=#name#");
			
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("sites.ehSites.dspCreateCustom","appRoot=#appRoot#&name=#name#");
			}
		</cfscript>
	</cffunction>


	<cffunction name="doDelete" access="public" returntype="void">
		<cfscript>
			var siteID = getValue("siteID");
			var deleteFiles = getValue("deleteFiles", false);
			var oSiteDAO = 0;
			var qrySite = 0;
			
			try {			
				// get site information
				oSiteDAO = getService("DAOFactory").getDAO("site");
				qrySite = oSiteDAO.get(siteID);

				// delete files (if requested and directory exists)
				if(isBoolean(deleteFiles) and deleteFiles and directoryExists( expandPath(qrySite.path))) {
					// make sure we are deleting something safe (if directory exists at all)
					if(qrySite.path neq "/" 
						and left(qrySite.path,6) neq "/homePortals/"
						and qrySite.path neq "/homePortals" 
						and left(qrySite.path,11) neq "/ColdBricks"
						and left(qrySite.path,1) eq "/" ) {
					} else {
						throw("You are trying to delete a restricted directory","coldBricks.validation");
					}

					deleteDir( expandPath(qrySite.path) );
				}
				
				// delete from local datastore
				oSiteDAO.delete(siteID);
				
				setMessage("info", "Site deleted");
				setNextEvent("sites.ehSites.dspMain");

			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("sites.ehSites.dspDelete","siteID=#siteID#");
				
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("sites.ehSites.dspDelete");
			}
		</cfscript>	
	</cffunction>
	
	<cffunction name="doRegister" access="public" returntype="void">
		<cfscript>
			var appRoot = getValue("appRoot");
			var name = getValue("name");
			var oUser = getValue("oUser");

			var oSiteDAO = 0;
			var qrySiteCheck = 0;
			var siteID = 0;

			try {
				if(name eq "") throw("Site name cannot be empty","coldBricks.validation");
				if(appRoot eq "") throw("Application root cannot be empty","coldBricks.validation");

				// check if site is already registered in coldbricks
				oSiteDAO = getService("DAOFactory").getDAO("site");
				qrySiteCheck = oSiteDAO.search(siteName = name);
				if(qrySiteCheck.recordCount gt 0) 
					throw("There is already another site registered with the name '#name#', please select a different site name.","coldBricks.validation");

				// make sure the approot points to an existing directory
				if(not directoryExists(expandPath(appRoot))) 
					throw("The given application directory does not exist. If you wish to create a new site use the 'Create Site' option.","coldBricks.validation");

				// check that the directory is not a restricted one
				if(left(appRoot,11) eq "/ColdBricks") {
					throw("You are trying to use a restricted directory as the application root. Please select a different application root.","coldBricks.validation");
				}

				// check that the target directory points to a valid homeportals application
				if( Not (directoryExists(expandPath(appRoot & "/config"))
						and fileExists(expandPath(appRoot & "/config/homePortals-config.xml.cfm")))
					and Not fileExists(expandPath(appRoot & "/homePortals-config.xml.cfm")))
					throw("The given application directory does not see,s point to a standard HomePortals application. Please check the directory and try again.","coldBricks.validation");

				// create site record for coldbricks
				siteID = oSiteDAO.save(id=0, siteName=name, path=appRoot, ownerUserID=oUser.getID(), createdDate=dateFormat(now(),"mm/dd/yyyy"), notes="");

				setMessage("info", "The site has been registered.");
				
				setNextEvent("sites.ehSites.dspHome","loadSiteID=#siteID#");

			} catch(coldBricks.validation e) {
				setMessage("warning",e.message);
				setNextEvent("sites.ehSites.dspRegister","appRoot=#appRoot#&name=#name#");
			
			} catch(any e) {
				setMessage("error",e.message);
				getService("bugTracker").notifyService(e.message, e);
				setNextEvent("sites.ehSites.dspRegister");
			}
		</cfscript>
	</cffunction>

	<cffunction name="doArchiveSite" access="public" returntype="void">
		<cfset var siteID = getValue("siteID")>
		<cfset var oSiteDAO = 0>
		<cfset var qrySite = 0>
		<cfset var dataRoot = getSetting("dataRoot")>
		<cfset var archivesPath = dataRoot & "/archives">
		<cfset var zipFilePath = "">
		<cfset var zipFileName = "">
		<cfset var deleteAfterDownload = getSetting("deleteAfterArchiveDownload")>
		<cfset var oCF8Extras = 0>
		
		<cftry>
			<!--- get site information ---->
			<cfset oSiteDAO = getService("DAOFactory").getDAO("site")>
			<cfset qrySite = oSiteDAO.get(siteID)>
		
			<!--- make sure the directory exists --->
			<cfif not directoryExists(expandPath(qrySite.path))>
				<cfthrow message="The application directory does not exist!" type="coldBricks.validation">
			</cfif>
		
			<!--- make sure the archives directory exists --->
			<cfif not directoryExists(expandPath(archivesPath))>
				<cfdirectory action="create" directory="#expandPath(archivesPath)#">
			</cfif>
			
			<!--- set name --->
			<cfset zipFileName = qrySite.siteName & "_" & dateFormat(now(),"mmddyy") & "_" & timeFormat(now(),"hhmmss") & ".zip">
			<cfset zipFilePath = expandPath( archivesPath & "/" & zipFileName)>
			
			<!--- create zip file --->
			<cfset oCF8Extras = createObject("component","ColdBricks.components.services.cf8extras").init()>
			<cfset oCF8Extras.createZip(zipFilePath, expandPath(qrySite.path))>
		
			<!--- download file --->
			<cfheader name="content-disposition" value="inline; filename=#zipFileName#">
			<cfif deleteAfterDownload>
				<cfcontent file="#zipFilePath#" type="application/zip" deletefile="true">
			<cfelse>
				<cfcontent file="#zipFilePath#" type="application/zip">
			</cfif>
		
			<cfset setMessage("info","Archive of site #qrySite.siteName# has been created. Archive name: #zipFileName#")>
		
			<cfcatch type="coldBricks.validation">
				<cfset setMessage("warning",cfcatch.message)>
			</cfcatch>
			<cfcatch type="any">
				<cfset setMessage("error",cfcatch.message)>
				<cfset getService("bugTracker").notifyService(cfcatch.message, cfcatch)>
			</cfcatch>
		</cftry>
		
		<cfset setNextEvent("sites.ehSites.dspMain")>
	</cffunction>

	<cffunction name="doSaveConfigFile" access="public" returntype="void">
		<cfscript>
			var xmlContent = getValue("xmlContent","");
			var configFile = getValue("configFile","");
			var oConfig = 0;
			
			try {
				// check if we can parse the xml as a valid config file
				try {
					oConfig = createObject("component","homePortals.components.homePortalsConfigBean").init().loadXML(xmlContent);
				} catch(any e) {
					setMessage("warning", "The given content is not a valid site config file.");
					dspEditXML();
					return;
				}

				fileWrite( expandPath( configFile ), xmlContent, "utf-8");
				
				// go to the xml editor
				setMessage("info", "Config file updated");
				setNextEvent("sites.ehSites.dspEditXML","siteID=#siteID#");

			} catch(any e) {
				setMessage("error", e.message);
				getService("bugTracker").notifyService(e.message, e);
				dspEditXML();
			}			
		</cfscript>
	</cffunction>	
	
	<!--- Private Methods --->

	<cffunction name="replaceTokens" access="private" returntype="void">
		<cfargument name="path" type="string" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="appRoot" type="string" required="true">
		<cfargument name="accountsRoot" type="string" required="true">
		<cfargument name="resourcesRoot" type="string" required="true">
		<cfargument name="contentRoot" type="string" required="true">
		<cfscript>
			var txtDoc = "";
			var appRootDotted = replace(arguments.appRoot,"/",".","ALL");
			
			if(len(appRootDotted) gt 1) {
				if(left(appRootDotted,1) eq ".") appRootDotted = right(appRootDotted,len(appRootDotted)-1);
				if(right(appRootDotted,1) neq ".") appRootDotted = appRootDotted & ".";
			}
			
			txtDoc = readFile(expandPath(arguments.path));
			txtDoc = replace(txtDoc, "$APP_NAME$", arguments.name, "ALL");
			txtDoc = replace(txtDoc, "$APP_ROOT$", arguments.appRoot, "ALL");
			txtDoc = replace(txtDoc, "$APP.ROOT$", appRootDotted, "ALL");
			txtDoc = replace(txtDoc, "$ACCOUNTS_ROOT$", arguments.accountsRoot, "ALL");
			txtDoc = replace(txtDoc, "$RESOURCES_ROOT$", arguments.resourcesRoot, "ALL");
			txtDoc = replace(txtDoc, "$CONTENT_ROOT$", arguments.contentRoot, "ALL");
			writeFile(expandPath(arguments.path), txtDoc);
		
		</cfscript>
	</cffunction>

	<cffunction name="writeFile" access="private" returntype="void">
		<cfargument name="path" type="string" required="true">
		<cfargument name="content" type="string" required="true">
		<cffile action="write" file="#arguments.path#" output="#arguments.content#">
	</cffunction>

	<cffunction name="createDir" access="private" returntype="void">
		<cfargument name="path" type="string" required="true">
		<cfdirectory action="create" directory="#arguments.path#">
	</cffunction>

	<cffunction name="deleteDir" access="private" returntype="void">
		<cfargument name="path" type="string" required="true">
		<cfdirectory action="delete" recurse="true" directory="#arguments.path#">
	</cffunction>

	<cffunction name="readFile" access="private" returntype="string">
		<cfargument name="path" type="string" required="true">
		<cfset var txt = "">
		<cffile action="read" file="#arguments.path#" variable="txt">
		<cfreturn txt>
	</cffunction>

	<cffunction name="directoryCopy" output="true">
		<cfargument name="source" required="true" type="string">
		<cfargument name="destination" required="true" type="string">
		<cfargument name="nameconflict" required="true" default="overwrite">
		<!---
		 Copies a directory.
		 
		 @param source 	 Source directory. (Required)
		 @param destination 	 Destination directory. (Required)
		 @param nameConflict 	 What to do when a conflict occurs (skip, overwrite, makeunique). Defaults to overwrite. (Optional)
		 @return Returns nothing. 
		 @author Joe Rinehart (joe.rinehart@gmail.com) 
		 @version 1, July 27, 2005 
		--->	
		<cfset var contents = "" />
		<cfset var dirDelim = "/">
		
		<cfif server.OS.Name contains "Windows">
			<cfset dirDelim = "\" />
		</cfif>
		
		<cfif not(directoryExists(arguments.destination))>
			<cfdirectory action="create" directory="#arguments.destination#">
		</cfif>
		
		<cfdirectory action="list" directory="#arguments.source#" name="contents">
		
		<cfloop query="contents">
			<cfif contents.type eq "file">
				<cffile action="copy" source="#arguments.source##dirDelim##name#" destination="#arguments.destination##dirDelim##name#" nameconflict="#arguments.nameConflict#">
			<cfelseif contents.type eq "dir" and name neq ".svn">
				<cfset directoryCopy(arguments.source & dirDelim & name, arguments.destination & dirDelim &  name) />
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="listDir" access="private" returntype="query">
		<cfargument name="path" type="string" required="true">
		<cfset var qry = queryNew("")>
		<cfdirectory action="list" directory="#arguments.path#" name="qry">
		<cfreturn qry>
	</cffunction>

</cfcomponent>	