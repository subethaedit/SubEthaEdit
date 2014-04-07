<%
' Declare our variables:
Dim objCDO  ' Our CDO object

Dim strTo   ' Strings to hold our email fields
Dim strFrom
Dim strSubject
Dim strBody

' First we'll read in the values entered and set by
' hand the ones we don't let you enter for our demo.
strTo = Request.Form("to")

' These could read the message subject and body in
' from a form just like the "to" field if we let you
' enter them.
'
'strSubject = Request.Form("subject")
'strBody    = Request.Form("body")
'
' We instead hard code them below just so people
' don't abuse this page.

'***********************************************************
' PLEASE CHANGE THESE SO WE DON'T APPEAR TO BE SENDING YOUR
' EMAIL. WE ALSO DON'T WANT THE EMAILS TO GET SENT TO US
' WHEN SOMETHING GOES WRONG WITH YOUR SCRIPT... THANKS
'***********************************************************
strFrom = "User Name <user@domain.com>"

strSubject = "Sample HTML Email sent from ASP 101!"

' This is multi-lined simply for readability.
' Notice that it is a properly formatted HTML
' message and not just plain text like most email.
' A lot of people have asked how to use form data
' in the emails so I added an example of including
' the entered address in the body of the email.
strBody = "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.0 Transitional//EN"">" & vbCrLf _
		& "<html>" & vbCrLf _
		& "<head>" & vbCrLf _
		& " <title>Sample Message From ASP 101</title>" & vbCrLf _
		& " <meta http-equiv=Content-Type content=""text/html; charset=iso-8859-1"">" & vbCrLf _
		& "</head>" & vbCrLf _
		& "<body bgcolor=""#FFFFCC"">" & vbCrLf _
		& " <h2>Sample Message From ASP 101</h2>" & vbCrLf _
		& " <p>" & vbCrLf _
		& "  This message was sent from a sample at" & vbCrLf _
		& "  <a href=""http://www.asp101.com"">ASP 101</a>." & vbCrLf _
		& "  It is used to show people how to send HTML" & vbCrLf _
		& "  formatted email from an Active Server Page." & vbCrLf _
		& "  If you did not request this email yourself," & vbCrLf _
		& "  your address was entered by one of our" & vbCrLf _
		& "  visitors." & vbCrLf _
		& "  <strong>" & vbCrLf _
		& "  We do not store these e-mail addresses." & vbCrLf _
		& "  </strong>" & vbCrLf _
		& " </p>" & vbCrLf _
		& " <font size=""-1"">" & vbCrLf _
		& "  <p>Please address all concerns to webmaster@asp101.com.</p>" & vbCrLf _
		& "  <p>This message was sent to: " & strTo & "</p>" & vbCrLf _
		& " </font>" & vbCrLf _
		& "</body>" & vbCrLf _
		& "</html>" & vbCrLf

' Some lines to help you check the formatting of your
' email before you actually start sending it to people.
'Response.Write "<pre>"
'Response.Write Server.HTMLEncode(strbody)
'Response.Write "</pre>"
'Response.End


' Ok... we've got all our values so let's get emailing:

' We just check to see if someone has entered anything into the to field.
' If it's equal to nothing we show the form, otherwise we send the message.
' If you were doing this for real you might want to check other fields too
' and do a little entry validation like checking for valid syntax etc.

' Note: I was getting so many bad addresses being entered and bounced
' back to me by mailservers that I've added a quick validation routine.
If strTo = "" Or Not IsValidEmail(strTo) Then
	%>
	<form action="<%= Request.ServerVariables("URL") %>" METHOD="post">
		Enter your e-mail address:<br />
		<input type="text" name="to" size="30" />
		<input type="submit" value="Send Mail!" />
	</form>
	<%
Else
	' Send our message:
	' Note that I'm using the Win2000 CDO and not CDONTS!
	' As such it will only work on Win2000.
	Set objCDO = Server.CreateObject("CDO.Message")
	With objCDO
		.To       = strTo
		.From     = strFrom
		.Subject  = strSubject
		.HtmlBody = strBody
		
		' BEFORE YOU UNCOMMENT THIS CHANGE THE VALUE OF
		' strFrom ABOVE!  IF YOU CAN'T FIND IT SEARCH FOR
		' strFrom = "User Name <user@domain.com>"
		' THANK YOU.
		'.Send
	End With
	Set objCDO = Nothing

	'==============================================================
	' You'd normally use the above, but I thought I should include
	' the CDONTS version for those of you still running NT4.
	'==============================================================
	'Set objCDO = Server.CreateObject("CDONTS.NewMail")
	'objCDO.From    = strFrom
	'objCDO.To      = strTo
	'objCDO.Subject = strSubject
	'objCDO.Body    = strBody
	'
	'objCDO.BodyFormat = 0 ' CdoBodyFormatHTML
	'objCDO.MailFormat = 0 ' CdoMailFormatMime
	'
	''objCDO.Cc  = "user@domain.com;user@domain.com"
	''objCDO.Bcc = "user@domain.com;user@domain.com"
	'
	'' Send the message!
	'objCDO.Send
	'Set objCDO = Nothing

	'Response.Write "Message sent to " & strTo & "!"
	Response.Write "Message ARE NO LONGER BEING SENT because of all the abuse the system was receiving!"
End If
%>

<% ' Only functions and subs follow!

' A quick email syntax checker.  It's not perfect,
' but it's quick and easy and will catch most of
' the bad addresses than people type in.
Function IsValidEmail(strEmail)
	Dim bIsValid
	bIsValid = True
	
	If Len(strEmail) < 5 Then
		bIsValid = False
	Else
		If Instr(1, strEmail, " ") <> 0 Then
			bIsValid = False
		Else
			If InStr(1, strEmail, "@", 1) < 2 Then
				bIsValid = False
			Else
				If InStrRev(strEmail, ".") < InStr(1, strEmail, "@", 1) + 2 Then
					bIsValid = False
				End If
			End If
		End If
	End If

	IsValidEmail = bIsValid
End Function
%>