<?Lassoscript
// Last modified 5/12/08 by ECL, Landmann InterActive

// FUNCTIONALITY
// Reset password form

// CHANGE NOTES
// 12/12/07
// Recoded for CMS v. 3.0
// 5/12/08
// Ported changes from LBT
// 6/3/09
// Fixed incorrect query on security question

// Convert action_params
Var:'vError'=(Action_Param:'Error');
Var:'vOption'=(Action_Param:'Option');
Var:'vUserEmail'=  (Action_Param:'UserEmail');
Var:'vQuestionID'=(Action_Param:'QuestionID');
Var:'vUserAnswer_Submit'=(Action_Param:'UserAnswer');

?>
<div align="left">
<form action="/reset_response.lasso" method="post">
<table border="0" cellpadding="2" cellspacing="2">
	<tr>
		<td colspan="3">
			<h2>Reset Password</h2>
		</td>
	</tr>
	<tr>
		<td colspan="2">
[If: $vError == '']
			Fill out the form below to reset your password. Your new password wiil be e-mailed to you.
[Else]
			[li_ShowError3: -ErrNum=(Var:'vError'), -Option=(Var:'vOption')]
[/If]
		</td>
	</tr>
	<tr>
		<td colspan="2"><strong>NOTE: </strong>[$svInputRequired] indicates required information.</td>
	</tr>
	<tr> 
		<td width="200" bgcolor="#666666" valign="middle" class="tablehead_10_white_right">Your E-Mail Address[$svInputRequired]</td>
		<td width="390" bgcolor="#f0f0f0">
			<input type="text" name="UserEmail" value="[Var:'vUserEmail']" size="36" maxlength="128">
		</td>
	</tr>
	<tr>
		<td width="200" bgcolor="#666666" valign="middle" class="tablehead_10_white_right">Security Question[$svInputRequired]</td>
<?Lassoscript
// Get Question ID and text
Var:'SQLSearchQuestions' = 'SELECT * FROM ' $svQuestionsTable;
Inline: $IV_Questions,-SQL=$SQLSearchQuestions;
?>
		<td width="390" bgcolor="#f0f0f0">
			<select name="QuestionID">
				<option value="" selected>=== Make Selection ===</option>
<?Lassoscript
			Records;
				Var:'vQuestion_ID'=(Field:'Question_ID');
				Var:'vQuestion_Text'=(Field:'Question_Text');
?>
				<option value="[Var:'vQuestion_ID']"[If:(Var:'vQuestion_ID')==(Var:'vQuestionID')] selected[/If]>[Var:'vQuestion_Text']</option>
			[/Records]</select>
[/Inline]
		</td>
	</tr>
	<tr>
		<td bgcolor="#666666" width="200" valign="middle" class="tablehead_10_white_right">Answer[$svInputRequired]</td>
		<td width="390" bgcolor="#f0f0f0">
			<input type="text" name="UserAnswer" value="[Var:'vUserAnswer_Submit']" size="36" maxlength="128">
		</td>
	</tr>
	<tr>
		<td colspan="2" bgcolor="#666666"> 
			<div align="center">
				<Input Type="submit" Name="-Nothing" Value="Submit">
			</div>
		</td>
	</tr>
</table>
</form>
