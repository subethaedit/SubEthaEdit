<?Lassoscript
// This script will check every 60 seconds to see if the server loses its mind

// From LassoTalk message from Johan Sölve on 2/3/10:
// Re: lasso 8.5.6 and DNS issues

// Debugging
// Var('svDebug' = 'Y');

Log_Critical('ServerIPCheck Loaded');

{
	// Give Lasso some time to start up
	Sleep(30*1000);

	While(true);

		If(Server_IP == '');

			Log_Critical(($svDomain)+' -- ServerIPCheck: failure detected');

			// Send e-mails
			If($svDebug == 'Y');
				Var('Subject' = 'ServerIPCheck DEBUG ON');
			Else;
				Var('Subject' = 'ServerIPCheck');
			/If;
			Var('Body' = ('The server '+($svDomain)+' has lost its\' IP and probably should be rebooted.
			'+(Server_Date)+' '+(Server_Time)));
			
			Email_Send:
				-Host=$svSMTP,
				-From=$svAdminEmail,
				-To=$svDeveloperEmail,
				-Subject=$Subject,
				-Username=$svAuthUsername,
				-Password=$svAuthPassword,
				-Sender=(($svDomain)+':ServerIPCheck'),
				-Body=(Include:'/site/libs/email_contact.txt');

			Loop_Abort;

		/If;

		Sleep(60*1000); // 60 seconds but check more often if you want

	/While;

}->Asasync(-Name='ServerIPCheck');

?>
