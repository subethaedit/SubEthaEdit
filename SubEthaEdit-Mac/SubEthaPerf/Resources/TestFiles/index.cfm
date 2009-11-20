<cfsetting showdebugoutput="false">
<cfinclude template="includes/flash_stylesheet.cfm">
<cfquery name="dsns" dbtype="query">
select name, driver, name+'.'+driver as selectValue
from application.datasources
</cfquery>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Genesis Query Evaluation Tool</title>
</head>

<body>
<div align="left" style="margin-left:-10px;">
<cfform format="flash" name="genesis" onload="loadContextMenu();onFormLoad();enableDrag();" skin="haloblue" height="600" width="1000">
	<cfformitem type="script">
	<cfoutput>
	
	   function onFormLoad(){
      var listener:Object = {};

      //put the controls in scope to avoid calling _root 
      var ds:mx.controls.ComboBox = ds;
	  var savedQlist:mx.controls.DataGrid = savedQlist;
	  
      var getObBrowser:Function = getObBrowser;
	  var getSavedQueries:Function = getSavedQueries;
	  var getSavedResults:Function = getSavedResults;
      listener.modelChanged = function(evt):Void {
	  //get the fav if exists
	  var so = SharedObject.getLocal("genesisFavDSN", "/genesis");
	  var dsn = so.data.DSN;
	  
	  _root.getSavedQueries();
	  _root.getSavedResults();
      <!--- select first item --->

	  for(var i:Number = 0; i<ds.length; i++)
	  {
	  		if(dsn != undefined && dsn != null && dsn != '')
			{
				if (ds.getItemAt([i]).data == dsn) 
				{ds.selectedIndex = i}
			}
			else
            {ds.selectedIndex = 0;}
	  }
	  ds.dispatchEvent({type:"change"});

	  
	  
      <!--- remove listener, so that we are not longer notified of model changes --->
      ds.removeEventListener('modelChanged',listener);
      }

      ds.addEventListener('modelChanged',listener);
   }
   
	
	function loadContextMenu(){
	##include "includes/actionscript/contextMenu.as"
	}
	
	function runQuery(q, dsn):Void{

	//clear the grid of all contents 
	qResultGrid.dataProvider.removeAll();

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	var qResultGrid = qResultGrid; 
	//declare variable to pass for logging
	var userip = '#cgi.REMOTE_ADDR#';
	responseHandler.onResult = function( results: Object ):Void {
		
		//if results is not an object with items then there was an error message returned by the cfc - put it in the message box
		
		if(results.items == undefined)
		{
		_root.resultsTabNav.selectedIndex = 1;
		_root.qMessages.setFocus();
		_root.qMessages.htmlText = results;
		mx.managers.CursorManager.removeBusyCursor();
		clearInterval(timeq);
		_root.qTime.text = _root.qTime.text + ' second(s)';
		}
		
		//else put the results in a grid
		
		else
		{
		clearInterval(timeq);
		_root.qTime.text = _root.qTime.text + ' second(s)';
		qResultGrid.setSize(0);
		
		//add a rowID column for row numbering
		
		qResultGrid.addColumnAt(0, 'rowID:Numeric');
		qResultGrid.__columns[0].headerText = '';
		qResultGrid.__columns[0].columnName = 'rowID';
		//add sort function
		qResultGrid.__columns[0].sortCompareFunction= "compareNumeric";

		var gridwidth:Number = 0; 
		
		//loop over column names returned and dynamically create the grid that will contain the results
		var k:Number = results.mTitles.length;
		
		for(var i:Number=0;i<k;i++)
			{
			var j = i+1;
			qResultGrid.addColumnAt(j, results.mTitles[i]);
			qResultGrid.__columns[j].headerText = results.mTitles[i];
			qResultGrid.__columns[j].columnName = results.mTitles[i];
			qResultGrid.vPosition = i;
			qResultGrid.selectedIndex = i;
			var titleLength:Number = Math.ceil(results.mTitles[i].length);
			
			var colwidth:Number = titleLength;

			gridwidth += Math.ceil(qResultGrid.__columns[j].width);
			
			//qResultGrid.__columns[j].visible = true;
			//qResultGrid.__columns[j].display = true;
			}
			
			
			qResultGrid.setDataProvider(results.items);
			qResultGrid.setSize(gridwidth+100, 225);
			qResultGrid.spaceColumnsEqually();
			//qResultGrid.__columns[0].width = 25;

			qResultGrid.sortOnHeaderRelease = false;

			//loop over all rows in the rowID column and assign a row number
			for(var j=0;j<results.items.length;j++)
			{
			var k = j+1;
			qResultGrid.editField(j, 'rowID', k);
			}
			_root.qRecordsReturned.text = results.items.length;
			
			qResultGrid.editable = true;
			qResultGrid.multipleSelection = true;
			qResultGrid.selectedIndex = undefined;
			mx.managers.CursorManager.removeBusyCursor();
			}
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert  this should really be rare since i do a cfcatch to return a result even if there is an error
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		clearInterval(timeq);
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	qResultGrid.removeAllColumns();
	_root.resultsHor.hPosition = 0;
	mx.managers.CursorManager.setBusyCursor();
	var timeq;
	_root.qTime.text = 0;
	_root.qRecordsReturned.text = '';
	timeq = setInterval( timeQuery, 1000);
	

	_root.resultsTabNav.selectedIndex = 0;
	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.executeQ(q, dsn, userip);
}

<!--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  --->
function getSavedQueries():Void{

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	var savedQlist = savedQlist;
	responseHandler.onResult = function( results: Object ):Void {
	
		//if results is not an object with items then there was an error message returned by the cfc - put it in the message box
		
		if(results.items == undefined)
		{
		_root.resultsTabNav.selectedIndex = 1;
		_root.qMessages.setFocus();
		_root.qMessages.htmlText = results;
		mx.managers.CursorManager.removeBusyCursor();
		}
		
		//else refresh the saved query list
		
		else
		{
		savedQlist.addColumnAt(0);
		savedQlist.__columns[0].headerText = 'Queries Saved on Server';
		savedQlist.__columns[0].columnName = 'qname';
		savedQlist.dataProvider = results.items;
		mx.managers.CursorManager.removeBusyCursor();
		}
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert  this should really be rare since i do a cfcatch to return a result even if there is an error
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	mx.managers.CursorManager.setBusyCursor();

	savedQlist.removeAllColumns();
	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.getSavedQueries();
}

function getSavedResults():Void{

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	var savedResultsList = savedResultsList;
	responseHandler.onResult = function( results: Object ):Void {
	
		//if results is not an object with items then there was an error message returned by the cfc - put it in the message box
		
		if(results.items == undefined)
		{
		_root.resultsTabNav.selectedIndex = 1;
		_root.qMessages.setFocus();
		_root.qMessages.htmlText = results;
		mx.managers.CursorManager.removeBusyCursor();
		}
		
		//else refresh the saved query list
		
		else
		{
		savedResultsList.addColumnAt(0);
		savedResultsList.__columns[0].headerText = 'Results Saved on Server';
		savedResultsList.__columns[0].columnName = 'resultsname';
		savedResultsList.dataProvider = results.items;

		mx.managers.CursorManager.removeBusyCursor();
		}
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert  this should really be rare since i do a cfcatch to return a result even if there is an error
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	mx.managers.CursorManager.setBusyCursor();
	
	savedResultsList.removeAllColumns();
	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.getSavedResults();
}

function saveQuery(q, qname):Void{

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	var getSavedQueries:Function = getSavedQueries;
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	
	responseHandler.onResult = function( results: Object ):Void {
		alert('Query saved to file.');
		//refresh the saved query list
		getSavedQueries();
		mx.managers.CursorManager.removeBusyCursor();
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert 
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	mx.managers.CursorManager.setBusyCursor();

	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.saveQuery(q, qname);
}
function deleteResults(resultsname):Void{

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	var getSavedResults:Function = getSavedResults;
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	
	responseHandler.onResult = function( results: Object ):Void {
		alert('Result file deleted from server.');
		//refresh the saved query list
		getSavedResults();
		mx.managers.CursorManager.removeBusyCursor();
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert 
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	mx.managers.CursorManager.setBusyCursor();

	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.deleteResults(resultsname);
}
function deleteQuery(qname):Void{

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	var getSavedQueries:Function = getSavedQueries;
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	
	responseHandler.onResult = function( results: Object ):Void {
		alert('Query deleted from server.');
		//refresh the saved query list
		getSavedQueries();
		mx.managers.CursorManager.removeBusyCursor();
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert 
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	mx.managers.CursorManager.setBusyCursor();

	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.deleteQuery(qname);
}
function getSavedQuery(qname):Void{

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	
	var responseHandler = {};
	
	//put the controls in scope to avoid calling _root
	
	responseHandler.onResult = function( results: Object ):Void {
		
		_root.qInput.text = results;
		_root.decorateSQL();
		
		mx.managers.CursorManager.removeBusyCursor();
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert 
		_root.qMessages.setFocus();
		
		_root.qMessages.text = 'Error Description: '+stat.description+chr(13)+'Error Code: '+stat.code+chr(13)+'Error Details: '+stat.details+chr(13)+'Error Level: '+stat.level+chr(13)+'Error Line: '+stat.line;
		mx.managers.CursorManager.removeBusyCursor();
	}
	
	mx.managers.CursorManager.setBusyCursor();

	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.getSavedQuery(qname);
}

<!--- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --->

function getObBrowser(dbtype, dbname){

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;

	var responseHandler = {};

	//put the controls in scope to avoid calling _root
	var ObBrowser = ObBrowser;
	var qInput = qInput;
	
	responseHandler.onResult = function( results: Object ):Void {
		//when results are back, populate the ObBrowser
		ObBrowser.dataProvider = results;
		//open the root
		if(ObBrowser.getIsBranch(ObBrowser.getTreeNodeAt(0))){
		ObBrowser.setIsOpen(ObBrowser.getTreeNodeAt(0), !ObBrowser.getIsOpen(ObBrowser.getTreeNodeAt(0)));}



		ObBrowser.selectedIndex = 0;
		ObBrowser.vScrollPolicy = "auto";
		ObBrowser.hScrollPolicy = "on";
		ObBrowser.maxHPosition = 400; 
		ObBrowser.dragEnabled = true;
		qInput.dragEnabled = true;
		ObBrowser.multipleSelection = true;
		

		mx.managers.CursorManager.removeBusyCursor();
		
}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert
		alert("Error while calling cfc:" + stat.description);
				mx.managers.CursorManager.removeBusyCursor();
	}
	var driver = dbtype.split(".")[1].toLowerCase();

if(driver == 'mssqlserver')
{
	mx.managers.CursorManager.setBusyCursor();
	//get service
	myService = connection.getService("genesis.cfc.genesis", responseHandler );
	//make call
	myService.getObBrowser(dbtype);
}
else
{
ObBrowser.removeAll();
alert('Object Browser is currently only available for SQL Server databases.');
}
}

<!--- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --->
function enableDrag(){
	
	var qInput = qInput;
	var ObBrowser = ObBrowser;

	_global.doDragEnter = function (event) {
		event.handled = true;
	}
	_global.doDragExit = function (event) {
		event.target.hideDropFeedback();
	}
	_global.doDragOver =  function (event) {
		event.target.showDropFeedback();
	}
	_global.doDragDropDG = function (event) {
		_global.doDragExit(event);
		var dragItems = event.dragSource.dataForFormat('treeItems');
		var dragItem = '';
		

		if(ObBrowser.selectedNode.getProperty('type') == 'table')
		{
		dragItem = ObBrowser.selectedNode.getProperty('path');
		}
		if(ObBrowser.selectedNode.getProperty('type') == 'storedproc')
		{
		dragItem = ObBrowser.selectedNode.getProperty('label');
		}
		
		if(ObBrowser.selectedNode.getProperty('type') == 'column' || ObBrowser.selectedNode.getProperty('type') == 'procparam')
		{
		
		for(var i:Number=0; i < ObBrowser.selectedNodes.length; i++)
		{
		if(i==0)
		{
		dragItem = ObBrowser.selectedNodes[i].getProperty('id');
		}
		if(i!=0)
		{
		dragItem = dragItem+ ', '+ObBrowser.selectedNodes[i].getProperty('id');
		}
		}

		}

		_root.qInput.text = _root.qInput.text + dragItem;

	}
	qInput.dragEnabled=true;
	ObBrowser.dragEnabled=true;

	qInput.addEventListener('dragEnter', _global.doDragEnter);
	qInput.addEventListener('dragDrop', _global.doDragDropDG);
	qInput.addEventListener('dragOver', _global.doDragOver);
	qInput.addEventListener('dragExit', _global.doDragExit);
}

function timeQuery(){
var time = Number(_root.qTime.text);

var n:Number = 1;
time = time + n; 
_root.qTime.text = time;
}


function decorateSQL(){

var keywords:Array = [["del'+'ete", "0x0000FF"],["into", "0x0000FF"],["set", "0x0000FF"],["values", "0x0000FF"],["insert", "0x0000FF"],["update", "0x0000FF"],["select", "0x0000FF"], ["from", "0x0000FF"], ["as", "0x0000FF"], ["on", "0x0000FF"], ["where", "0x0000FF"], ["left", "0xFF00FF"], ["right", "0xFF00FF"], ["inner", "0xAAAAAA"], ["outer", "0xAAAAAA"], ["join", "0xAAAAAA"], ["and", "0xAAAAAA"]];
var t = qInput.text.toLowerCase();
var i = 0;

   _root.onEnterFrame = function ()
   {
      if(i < keywords.length) {
         //do one iteration of the loop 
         _root.updateSQL(i);
         i++;
      }
      else {
         //end the loop 
         _root.onEnterFrame = undefined;         
      }
   }

  _root.updateSQL = function (i){

var x = keywords[i][0];

var myTextFormat:Object = _root.qInput.label.getTextFormat();
myTextFormat.bold = true;
myTextFormat.color = keywords[i][1];

var u:Number = t.indexOf(x);
if(u != -1)
	{
	for(var w:Number =0; w<t.length; w++)
		{
		var y:Number = x.length;
		var z:Number = Number(w)+Number(y);
		var v:Number = Number(w) - 1;

			if(t.substr(w, x.length) == x  && ((t.substr(z, 1) == ' ' || t.substr(z, 1) == ')' ||  t.substr(z, 1) == '\r') && (t.substr(v, 1) == '' || t.substr(v, 1) == ' ' || t.substr(v, 1) == '\r' || t.substr(v, 1) == '(')))
				{
					if(_root.qInput.label.getTextFormat() != myTextFormat)
					{
					_root.qInput.label.setNewTextFormat(w, z, myTextFormat);
					}
				}
		}
	}
}	
}


function saveDSN(){
var dsn = ds.selectedItem.data;
// Create a local shared object 
var so = SharedObject.getLocal("genesisFavDSN", "/genesis");

so.data.DSN = dsn;

// write it out to the client
so.flush();
var dsndisplay = dsn.split(".")[0]
alert('Default DSN now set to '+dsndisplay);
}

function exportGrid(grid, filename, report_output){

	//create connection
	var connection:mx.remoting.Connection = mx.remoting.NetServices.createGatewayConnection("http://#cgi.HTTP_HOST#/flashservices/gateway/");
	//declare service
	var myService:mx.remoting.NetServiceProxy;
	
	var responseHandler = {};
	

	//put the controls in scope to avoid calling _root
	var grid = grid;
	var getSavedResults:Function = getSavedResults;
	
	responseHandler.onResult = function( results: Object ):Void {
		
		//when results are back...
		getSavedResults();
		grid.resultsname.headerText = 'Results Saved on Server';
		
	}
	responseHandler.onStatus  = function( stat: Object ):Void {
		//if there is any error, show an alert
		alert("Error while calling cfc:" + stat.description);
	}
	alert('Saving results to server.  You may continue to work while the results are saved.  When save is complete, file list will be refreshed.');
	//get service
	myService = connection.getService("genesis.cfc.export_grid", responseHandler );
	//make call
	myService.export_grid(grid.dataProvider, filename, report_output);
}
function copyToClipboard(){
	var dg = qResultGrid;
	if(qResultGrid.selectedItems != undefined || qResultGrid.selectedItem != undefined)
	{
	var copySel:Boolean = true;
	}
	else{
	var copySel:Boolean = false;
	}
	
	var font = dg.getStyle('fontFamily');
	var size = dg.getStyle('fontSize');

<!--- 	var currow = dg.selectedIndex;
	if(currow == undefined || currow == null || currow == '')
	{currow = 0;}
	for (var i:Number = 0; i<dg.length; i++) 
	{
	dg.vPosition = i;
	}
	dg.vPosition = currow;
 --->

	var str:String = '<html><body><table width="'+dg.width+'" border="1"><thead><tr width="'+dg.width+'">';
	for(var i=0;i<dg.__columns.length;i++)
	{

	var style = 'style="font-family:'+font+';font-size:'+size+'pt;"';
	var align = 'align="left"'
			str+= "<th nowrap "+style+" "+align+">"+dg.__columns[i].columnName+"</th>";	
		}
		str += "</tr></thead><tbody>";

	for(var j=0;j<dg.length;j++)
	{
		str+="<tr width=\""+Math.ceil(dg.width)+"\">";
		var style = 'style="font-family:'+font+';font-size:'+size+'pt;"';
		var align = 'align="left"'
		var str2;
		var str3; 
		var sel;
		for(var i=0;i<dg.__columns.length;i++)
		{

				if(dg.__columns[i].labelFunction != undefined){
				if(dg.__columns[i].labelFunction(dg.getItemAt(j),dg.__columns[i].columnName) != null)
				{
				str3 = dg.__columns[i].labelFunction(dg.getItemAt(j),dg.__columns[i].columnName);
				}
				else 
				{
				str3 = '';
				}
					str += "<td nowrap width=\""+Math.ceil(dg.__columns[i].width)+"\" "+style+" "+align+">"+str3+"</td>";}

					
					if(dg.getItemAt(j)[dg.__columns[i].columnName] != null) 
					{
					str2 = dg.getItemAt(j)[dg.__columns[i].columnName];
					}
					else
					{
					str2 = '';
					}
					str += "<td nowrap width=\""+Math.ceil(dg.__columns[i].width)+"\" "+style+" "+align+">"+str2+"</td>";
			
		}
		str += "</tr>";
	}
	str+="</tbody></table></body></html>";
	System.setClipboard(str);
	alert('Copy Done. Clipboard results are formatted for Excel.');
}
	</cfoutput>
	</cfformitem>
<cfformgroup type="panel" label="GENESIS" style="#panel_style#" height="100%" width="100%">
	<cfformgroup type="hbox">
		<cfformgroup type="vbox" width="260" id="treeVbox">
			
		<cfformgroup type="accordion" style="#accordion_style#">
			
				<cfformgroup type="page" label="Object Browser">
					<cfinput type="button" name="setFavDSN" label="Set Current DSN as Default"  value="Set Current DSN as Default" onclick="saveDSN();" width="220">
					<cfinput type="button" name="refreshObBrowser" value="Refresh Object Browser" onclick="getObBrowser(ds.value, ds.text);" width="220">
					<cftree name="ObBrowser" width="220" height="360" onchange="loadContextMenu();" style="#tree_style#"></cftree>
				</cfformgroup>
				
				<cfformgroup type="page" label="Query Options">
					<cfinput type="text" name="saveThisQueryName" label="Save Query as: " tooltip="Enter a filename for the query you would like to save and then click Save Query" onchange="
					if(saveThisQueryName.text != '')
					{
					saveThisQuerybtn.enabled = true;
					}" width="100">  
					<cfinput type="button" name="saveThisQuerybtn" value="Save Query" disabled="true" onclick="
					var k:Number = savedQlist.length;
					if(k!=0)
					{
					for(var i:Number = 0; i<k; i++)
					{
					if(savedQlist.getItemAt(i).qname.toLowerCase() == saveThisQueryName.text.toLowerCase()+'.txt')
						{
							var myClickHandler = function (evt)
							{
    						if (evt.detail == mx.controls.Alert.OK)
								{
         						_root.saveQuery(_root.qInput.text, _root.saveThisQueryName.text);
    							}
	  						}
					
  					alert('Query '+saveThisQueryName.text+' already exists on this server.'+chr(13)+'To overwrite click OK, to cancel and rename click CANCEL', 'Warning', mx.controls.Alert.OK  | mx.controls.Alert.CANCEL, myClickHandler);
					break;
					
					
						}
						
					if((savedQlist.getItemAt(i).qname.toLowerCase() != saveThisQueryName.text.toLowerCase()+'.txt') && i == k-1)
					{
					saveQuery(qInput.text, saveThisQueryName.text);
					}
					}
					}
					else
					{saveQuery(qInput.text, saveThisQueryName.text);}
					" width="220">
					<cfgrid name="savedQlist" width="220" height="185" onchange="
					if(savedQlist.selectedIndex != undefined)
					{
					loadQbtn.enabled = true;
					delQbtn.enabled = true;
					}" rowheaders="no">
					<cfgridcolumn name="qname" header="Queries Saved on Server" />
					</cfgrid>
					<cfinput type="button" name="loadQbtn" value="Load Query" onclick="if(savedQlist.selectedIndex != undefined){getSavedQuery(savedQlist.selectedItem.qname);}else{alert('Please select a query to load');}" disabled="true" width="220">
					<cfinput type="button" name="delQbtn" value="{'Del'+'ete'} Query" onclick="if(savedQlist.selectedIndex != undefined){
					{
							var myClickHandler = function (evt)
							{
    						if (evt.detail == mx.controls.Alert.OK)
								{
         						_root.deleteQuery(_root.savedQlist.selectedItem.qname);
    							}
	  						}
					
  					alert('Are you sure you want to del'+'ete '+savedQlist.selectedItem.qname, 'Warning', mx.controls.Alert.OK  | mx.controls.Alert.CANCEL, myClickHandler);
						}
					
					
					}
					
					else{alert('Please select a query to del'+'ete');}" disabled="true" width="220">
				</cfformgroup>
				<cfformgroup type="page" label="Results Options">
					 <cfinput type="text" name="saveResultsName" label="Save Results as: " tooltip="Enter a filename for the results you would like to save and then click Save Results" onchange="
					if(saveResultsName.text != '' && report_output.selectedData != '')
					{
					saveResultsbtn.enabled = true;
					}" width="100">  
					<cfformgroup type="horizontal" style="margin-left:-80;">
					<cfinput type="radio" name="report_output" value=".xls" label=".xls" onchange="if(saveResultsName.text != '' && report_output.selectedData != ''){saveResultsbtn.enabled = true;}" checked="yes">
					<cfinput type="radio" name="report_output" value=".csv" label=".csv" onchange="if(saveResultsName.text != '' && report_output.selectedData != ''){saveResultsbtn.enabled = true;}">
					<cfinput type="radio" name="report_output" value=".txt" label=".txt" onchange="if(saveResultsName.text != '' && report_output.selectedData ''){saveResultsbtn.enabled = true;}">
					</cfformgroup>
					<cfinput type="button" name="saveResultsbtn" value="Save Results" disabled="true" onclick="if(qResultGrid.length > 0){

					var k:Number = savedResultsList.length;
					if(k!=0)
					{
					for(var i:Number = 0; i<k; i++)
					{
					if(savedResultsList.getItemAt(i).resultsname.toLowerCase() == saveResultsName.text.toLowerCase()+report_output.selectedData)
						{
							var myClickHandler = function (evt)
							{
    						if (evt.detail == mx.controls.Alert.OK)
								{
         						_root.exportGrid(_root.qResultGrid, _root.saveResultsName.text, _root.report_output.selectedData);
    							}
	  						}
					
  					alert('Results '+saveResultsName.text+' already exist on this server.'+chr(13)+'To overwrite click OK, to cancel and rename click CANCEL', 'Warning', mx.controls.Alert.OK  | mx.controls.Alert.CANCEL, myClickHandler);
					break;
					
					
						}
						
					if((savedResultsList.getItemAt(i).resultsname.toLowerCase() != saveResultsName.text.toLowerCase()+report_output.selectedData) && i == k-1)
					{
					exportGrid(qResultGrid, saveResultsName.text, report_output.selectedData);
					}
					}
					}
					else{exportGrid(qResultGrid, saveResultsName.text, report_output.selectedData);}
					}else{alert('There are no results to save.');}" width="220">
					<cfgrid name="savedResultsList" width="220" height="185" onchange="
					if(savedResultsList.selectedIndex != undefined)
					{
					openResultsbtn.enabled = true;
					delResultsbtn.enabled = true;
					}" rowheaders="no">
					<cfgridcolumn name="resultsname" header="Results Saved on Server" />
					</cfgrid>
					<cfinput type="button" name="openResultsbtn" value="Open Results" onclick="if(savedResultsList.selectedIndex != undefined){getURL('cfc/savedresults/'+savedResultsList.selectedItem.resultsname, '_blank');}else{alert('Please select a results file to open');}" disabled="true" width="220">
					<cfinput type="button" name="delResultsbtn" value="{'Del'+'ete'} Results" onclick="if(savedResultsList.selectedIndex != undefined){
					{
							var myClickHandler = function (evt)
							{
    						if (evt.detail == mx.controls.Alert.OK)
								{
         						_root.deleteResults(_root.savedResultsList.selectedItem.resultsname);
    							}
	  						}
					
  					alert('Are you sure you want to del'+'ete '+savedResultsList.selectedItem.resultsname, 'Warning', mx.controls.Alert.OK  | mx.controls.Alert.CANCEL, myClickHandler);
						}
					}
					else{alert('Please select a result file to del'+'ete');}" disabled="true" width="220">
					
					</cfformgroup>
				</cfformgroup>
		</cfformgroup>

		<cfformgroup type="vbox" width="690" style="margin-bottom:0">

					<cfformgroup type="horizontal" style="margin-left:-13; verticalGap:0; margin-bottom:0;">
					<cfselect name="ds" id="ds" label="DSN:  " query="dsns" value="selectValue" display="name" onchange="getObBrowser(ds.value, ds.text);" width="125" />
					<cfinput type="button" name="execQ" value="Execute Query" onclick="
					if(qInput.text != undefined && qInput.text != null && qInput.text.length > 0)
					{qMessages.text = ''; 
					var selStart:Number=Selection['lastBeginIndex'];
					var selEnd:Number=Selection['lastEndIndex'];
					var qInputtext:String = qInput.text;
					var diff = selEnd - selStart;
					var selText = qInputtext.substr(selStart, diff);
					if(selText != undefined && selText != '')
					{
					runQuery(selText, ds.text);
					_root.qInput.setFocus();
					Selection.setSelection(selStart, selEnd);
					}
					else
					{
					runQuery(qInput.text, ds.text);
					}
					}
					else{alert('You did not enter a query.  Please try again.');}">
					<cfinput type="button" name="clearQ" value="Clear Query" onclick="
					if(qInput.length > 0)
					{
							var myClickHandler = function (evt)
							{
    						if (evt.detail == mx.controls.Alert.OK)
								{
         						_root.qInput.text = '';
								var myTextFormat:Object = _root.qInput.label.getTextFormat();
								myTextFormat.bold = false;
								myTextFormat.color = 0x000000;
								_root.qInput.label.setNewTextFormat(0, 1, myTextFormat);
    							}
	  						}
					
  					alert('Are you sure you want to reset this query?  Unsaved changes will be lost.', 'Warning', mx.controls.Alert.OK  | mx.controls.Alert.CANCEL, myClickHandler);
						}
					else{alert('Clear what? ;)');}
					">
					<cfinput type="button" name="setClipBoard" value="Results To Clipboard" onclick="
					if(qResultGrid.dataProvider.length > 0)
					{
					copyToClipboard();
					}
					else
					{
					alert('There are no results to copy.');
					}">
					<cfinput type="button" name="getQLog" value="View Query Log" onclick="getURL('#application.log_url#', '_blank');">
					</cfformgroup>
			
						<cfformgroup type="vbox" style="cornerRadius:5; margin-bottom:0; margin-left:-12;" width="680" height="100%" id="queryVbox">
							<cftextarea name="qInput" height="120" width="660" html="true" onchange="
							var qInputtext:String = qInput.text;
							var qInputHtml:String = qInput.htmlText;
							var textLen:Number = qInputtext.length;
							var lastCharPos:Number = textLen - 1;
							
							if(qInputtext.substr(lastCharPos, 1) == ' '  || qInputHtml.substr(lastCharPos, 1) == chr(13) || qInputtext.substr(lastCharPos, 1) == '\r')
							{
							decorateSQL();
							}" onFocus="decorateSQL();"></cftextarea>
								<cfformgroup type="hbox" style="margin-bottom:0; margin-top:0; margin-left:8;">
									<cfformgroup type="vbox"  style="verticalGap:-5; margin-bottom:0;">
									<cfinput type="text" name="qTime" label="Execution Time" disabled="true" style=" background-color: ##6699ff; borderStyle:none; fontWeight:bold; disabledColor:##000000;">						
									</cfformgroup>
									<cfformgroup type="vbox"  style="verticalGap:-5; margin-bottom:0;">
									<cfinput type="text" name="qRecordsReturned" label="Records Returned" disabled="true" style="borderStyle:none; fontWeight:bold; disabledColor:##000000; background-color: ##6699ff;">
									</cfformgroup>
						</cfformgroup>
			</cfformgroup>


				<cfformgroup type="vbox"  style="cornerRadius:5; margin-top:0;" width="680"id="resultsVbox">
				
					<cfformgroup type="tabnavigator" id="resultsTabNav" height="317" style="#tabnav_style# margin-bottom:0; verticalGap:0; margin-top:0;">
					
						<cfformgroup type="page" label="Results">
						
							<cfformgroup type="horizontal" width="640" height="255" id="resultsHor">
								<cfgrid name="qResultGrid" rowheaders="no" height="100%" width="100%" selectmode="row">
									<cfgridcolumn name="QueryResults" header="">	
								</cfgrid>
							</cfformgroup>
								
						</cfformgroup>
						
						<cfformgroup type="page" label="Messages">
							<cftextarea name="qMessages" height="195" style="themeColor:##FF0000;" html="true" width="610"></cftextarea>
						</cfformgroup>
						
					</cfformgroup>		

				</cfformgroup>
			
			</cfformgroup>
			
		</cfformgroup>

</cfformgroup>

</cfform>
</div>
<div align="center" style="font:Verdana; font-size:10px;">Created by Todd Sharp - <a href="http://cfsilence.com">http://cfsilence.com</a>.  Bugs/Feedback:  <a href="mailto:genesis_bugs@cfsilence.com?subject=genesis feedback">genesis_bugs@cfsilence.com</a></div>
</body>
</html>
<cfsetting showdebugoutput="true">