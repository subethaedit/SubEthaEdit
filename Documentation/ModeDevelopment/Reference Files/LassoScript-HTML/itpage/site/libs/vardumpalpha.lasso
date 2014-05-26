<?Lassoscript
// Last modified 12/21/09 by ECL

// CHANGE NOTES
// 8/14/08
// First implementation
// 12/21/09
// Added Response_FilePath

// If Debug is on, dump out Page Info, Action_Params and Variables
Local:'VarDumpPage' = string;
#VarDumpPage += '<p class="debug"><font color="green"><strong>PAGE INFO</strong></font><br>\n';
#VarDumpPage += '<strong>ProcessCleanURLs</strong> = ' ($ProcessCleanURLs) '<br>\n';
#VarDumpPage += '<strong>ResponseFilepath</strong> = ' (Response_FilePath) '<br>\n';
#VarDumpPage += '<strong>ResponseFilepathEval</strong> = ' (Var:'ResponseFilepathEval') '<br>\n';
#VarDumpPage += '<strong>ServeThisPage</strong> = ' (Var:'ServeThisPage') '<br>\n';
#VarDumpPage += '<strong>Referrer_URL</strong> = ' (Referrer_URL) '<br>\n';
#VarDumpPage += '</p>\n';
Output:(#VarDumpPage),-EncodeNone;

// VarDumping Session Info
Local:'VarDumpSession' = string;
#VarDumpSession += '<p class="debug"><font color="green"><strong>SESSION INFO</strong></font><br>\n';
#VarDumpSession += '<strong>Session_ID Admin</strong> = ' (Session_ID: -Name=$svSessionAdminName) '<br>\n';
#VarDumpSession += '<strong>svUser_ID</strong> = ' (Var:'svUser_ID') '<br>\n';
#VarDumpSession += '<strong>svUser_LoginID</strong> = ' (Var:'svUser_LoginID') '<br>\n';
#VarDumpSession += '<strong>svUserPrivs_Priv</strong> = ' (Var:'svUserPrivs_Priv') '<br>\n';
#VarDumpSession += '<strong>svUserTypes_TypeID</strong> = ' (Var:'svUserTypes_TypeID') '<br>\n';
#VarDumpSession += '<strong>svUser_WGID</strong> = ' (Var:'svUser_WGID') '<br>\n';
#VarDumpSession += '<strong>User Name</strong> = ' (Var:'svAdmin_FName') ' ' (Var:'svAdmin_LName') '<br>\n';
#VarDumpSession += '</p>\n';
Output:(#VarDumpSession),-EncodeNone;


// VarDumping action_params
Local:'VarDumpAction' = string;
#VarDumpAction += '<p class="debug"><font color="green"><strong>ACTION_PARAMS DUMP</strong></font><BR>\n';
Local:'params'=(action_params);
If: (#params->Size) >> 0;
	Loop: (#params->Size);
		If: !((#params ->get:(loop_count)->first)->(beginswith:'-'));
			#VarDumpAction += '<strong>';
			#VarDumpAction += (#params ->get:(loop_count)->first);
			#VarDumpAction += '</strong>';
			#VarDumpAction += ' = ';
			#VarDumpAction += (#params ->get:(loop_count)->second);
			#VarDumpAction += '<br>\n';
		/If;
	/Loop;
/If;
#VarDumpAction->(RemoveTrailing('<br>\n'));
#VarDumpAction += '</p>\n';
Output:(#VarDumpAction),-EncodeNone;

// Variable Dump
Output:('\n'),-EncodeNone;
Output:('<p class="debug"><font color="green"><strong>VARIABLE DUMP</strong></font><br>\n'),-EncodeNone;

// Used to output to the browser, if desired
Var:'VarsArray' = array;
Loop:(Vars)->size;
	// Do not output system vars
	If:((Vars)->(get:(Loop_Count))->name)->(BeginsWith:'_') == false;
		// Do not output VarDump (results in double output)
		If:((Vars)->(get:(Loop_Count))->name)->(BeginsWith:'VarDump') == false && 
			((Vars)->(get:(Loop_Count))->name)->(BeginsWith:'VarsArray') == false;
			// Do not output System Vars (those starting with sv)
			If:((Vars)->(get:(Loop_Count))->name)->(BeginsWith:'sv') == false;
				// Do not output the Inline Vars
				If:((Vars)->(get:(Loop_Count))->name)->(BeginsWith:'IV') == false;
					// Do not output the action_params, we did that above
					If:((Vars)->(get:(Loop_Count))->name)->(BeginsWith:'params') == false;
						// Do not output the URLLabelMap
						If:((Vars)->(get:(Loop_Count))->name)->(Equals:'URLLabelMap') == false;
							// Insert into the array
							$VarsArray->(Insert:(Vars->(Get:(Loop_Count))->(Get:1)) = (Vars->(Get:(Loop_Count))->(Get:2)));
						/If;
					/If;
				/If;
			/If;
		/If;
	/If;
/Loop;

// Sort the Array
$VarsArray->(Sort:True);

// Output to the browser
Loop:($VarsArray)->size;
	Output:('<strong>'(($VarsArray)->get:(Loop_Count)->first) '</strong> = ' (($VarsArray)->get:(Loop_Count)->second) '<br>\n'),-EncodeNone;
/Loop;

Output:('</p>\n'),-EncodeNone;
Output:('<p class="debug"><font color="green">vardumpalpha.lasso loaded</font></p>\n'),-EncodeNone;
?>
