{rtf1ansiansicpg1252cocoartf949cocoasubrtf430
{fonttblf0fswissfcharset0 Helvetica;}
{colortbl;red255green255blue255;}
margl1440margr1440vieww22160viewh20320viewkind0
pardtx720tx1440tx2160tx2880tx3600tx4320tx5040tx5760tx6480tx7200tx7920tx8640qlqnaturalpardirnatural

f0fs24 cf0 <script language=javascript runat=server> 

function inStrGrp(src,reg){
var regex=new RegExp("[" + reg + "]","i");
return regex.test(src);
}

</script> 
<%
Nav1 = "Programs & Classes"
Nav2 = "Work Experience"
Database = "WorkExperience"

If Request.Form("QuizSubmit") <> "" Then
	Answer_Right = 0 
	' Old Key B, C, A, B, C
	If Request("Q1") = "A" Then
		Answer_Right = Answer_Right + 1
	End If	
	If Request("Q2") = "A" Then
		Answer_Right = Answer_Right + 1
	End If	
	If Request("Q3") = "C" Then
		Answer_Right = Answer_Right + 1
	End If	
	If Request("Q4") = "A" Then
		Answer_Right = Answer_Right + 1
	End If	
	If Request("Q5") = "B" Then
		Answer_Right = Answer_Right + 1
	End If	
	If Request("Q6") = "B" Then
		Answer_Right = Answer_Right + 1
	End If	
	
	If Answer_Right < 6 Then 
		Response.Redirect("quiz.asp?f=true")
	End If
	
End If


If Request.Form("submit") <> "" Then
	If FieldsValid(Request.Form("UserID"), Request.Form("PIN")) <> 1 Then  
		bad_login = true
		display = "login"
	Else	
		display = "form"
		If IsBannerID(Request("UserID")) = True Then
				BannerID = Request("UserID")
		Else
				Set oServerXML = CreateObject("Msxml2.ServerXMLHTTP")
                oServerXML.Open "GET", "https://www.url.com/folder1/folder2/webservice.asmx/GetBannerID?SSN_PIDM=" & Request("UserID") & "", False
                oServerXML.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
                oServerXML.send
                BannerID = oServerXML.responsexml.Text
			End If
	End If
End If
%>
<!-- #INCLUDE VIRTUAL="/includes/dsn.asp"-->
<!-- #INCLUDE VIRTUAL="/includes/top.asp"-->

        <div class="breadcrumb">
		<a href="/">Home</a> &gt; <a href="/academic/">Programs &amp; Classes</a> &gt; <a href="/programs/wexp/">Work Experience</a>
		<h2>Application</h2>
		</div>
	
	
		<style type="text/css">
		
		#ProgressBar {
			margin: 0;
			padding: 17px 5px;
			background: url('ProgressBar/bar_bg.gif') top center repeat-x;
		}
		#ProgressBar li {
			display: inline;
			padding: 17px 5px;
			background: url('ProgressBar/step_gray.gif') top center no-repeat;
		}
		#ProgressBar li.complete {
			background: url('ProgressBar/step_green.gif') top center no-repeat;
		}
		</style>	
		
		<div style="text-align:center;margin-top:10px;margin-bottom:10px;">	
	
		 
		
<% Select Case display %>

<% Case "form"%>
		<ol id="ProgressBar">
		  <li class="complete">Orientation</li>
		  <li class="complete">Log In</li>
		  <li>Application</li>
		  <li>Choose a Course</li>
		  <li>Register</li>
		 </ol>
		</div>
		
<style type="text/css">
	.Required {
		/* border: 1px solid red; */
		background: #fefdef;
	}	
</style>
<script Language="JavaScript" Type="text/javascript"><!--
function FrontPage_Form1_Validator(theForm)
{

  if (theForm.Last_Name.value == "")
  {
    alert("Please enter a value for the "Last Name" field.");
    theForm.Last_Name.focus();
    //theForm.Last_Name.className = 'Required';
    return (false);
  }

  if (theForm.First_Name.value == "")
  {
    alert("Please enter a value for the "First Name" field.");
    theForm.First_Name.focus();
    return (false);
  }

  if (theForm.Phone_Number.value == "")
  {
    alert("Please enter a value for the "Phone Number" field.");
    theForm.Phone_Number.focus();
    return (false);
  }

  if (theForm.Email_Address.value == "")
  {
    alert("Please enter a value for the "Email Address" field.");
    theForm.Email_Address.focus();
    return (false);
  }

  if (theForm.Employer_Name.value == "")
  {
    alert("Please enter a value for the "Employer" field.");
    theForm.Employer_Name.focus();
    return (false);
  }

  if (theForm.Employer_Address.value == "")
  {
    alert("Please enter a value for the "Employer Address" field.");
    theForm.Employer_Address.focus();
    return (false);
  }

  if (theForm.Work_Phone.value == "")
  {
    alert("Please enter a value for the "Work Phone/Extension" field.");
    theForm.Work_Phone.focus();
    return (false);
  }

  if (theForm.Supervisor.value == "")
  {
    alert("Please enter a value for the "Supervisor" field.");
    theForm.Supervisor.focus();
    return (false);
  }

  if (theForm.Job_Title.value == "")
  {
    alert("Please enter a value for the "Job Title" field.");
    theForm.Job_Title.focus();
    return (false);
  }

  if (theForm.Description_of_Duties.value == "")
  {
    alert("Please enter a value for the "Brief Description of Duties" field.");
    theForm.Description_of_Duties.focus();
    return (false);
  }

  var radioSelected = false;
  for (i = 0;  i < theForm.Pay_Status.length;  i++)
  {
    if (theForm.Pay_Status[i].checked)
        radioSelected = true;
  }
  if (!radioSelected)
  {
    alert("Please select either Paid or Unpaid.");
    return (false);
  }

  if (theForm.Hours_Per_Week.value == "")
  {
    alert("Please enter a value for the "Number of Hours per Week" field.");
    theForm.Hours_Per_Week.focus();
    return (false);
  }
  
  if (!isInteger(theForm.Hours_Per_Week.value)) {
  	alert("You must enter a number for the "Number of Hours per Week" field.");
	theForm.Hours_Per_Week.focus();
	return (false);
  }
  
  if (theForm.College_Major.value == "")
  {
    alert("Please enter a value for the "College Major" field.");
    theForm.College_Major.focus();
    return (false);
  }

  if (theForm.Career_Goal.value == "")
  {
    alert("Please enter a value for the "Career Goal" field.");
    theForm.Career_Goal.focus();
    return (false);
  }
  return (true);
}

function isInteger (s)
   {
      var i;

      if (isEmpty(s))
      if (isInteger.arguments.length == 1) return 0;
      else return (isInteger.arguments[1] == true);

      for (i = 0; i < s.length; i++)
      {
         var c = s.charAt(i);

         if (!isDigit(c)) return false;
      }

      return true;
   }

   function isEmpty(s)
   {
      return ((s == null) || (s.length == 0))
   }

   function isDigit (c)
   {
      return ((c >= "0") && (c <= "9"))
   }
</script>

<form method="post" id="Form1" onsubmit="return FrontPage_Form1_Validator(this)" action="class.asp">
		<div align="center">
		<table border="0" id="table1" width="470" style="text-align:left;">
			<tr>
				<td valign="top"><b>B.C. ID#</b></td>
				<td><input type="hidden" name="BC_ID_Number" value="<%=BannerID%>"/><%=BannerID%></td>
			</tr>
			<tr>
			 <td valign="top"><b>Semester</b></td>
			 <td><select name="Semester">
              	    <option value="200930">Spring 2009</option>
			       <!-- <option value="200850">Summer 2008</option> -->
			       <option value="200870">Fall 2008</option>
			       <!-- <option value="200830">Spring 2008</option> -->
			     </select></td>
			</tr>
            <tr>
				<td valign="top"><b>First Name</b></td>
				<td><input type="text" name="First_Name" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Last Name</b></td>
				<td><input type="text" name="Last_Name" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Phone</b></td>
				<td><input type="text" name="Phone_Number" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Email Address</b></td>
				<td><input type="text" name="Email_Address" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Employer</b></td>
				<td><input type="text" name="Employer_Name" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Employer Address</b></td>
				<td><textarea rows="3" name="Employer_Address" cols="25"></textarea></td>
			</tr>
			<tr>
				<td valign="top"><b>Work Phone/Extension</b></td>
				<td><input type="text" name="Work_Phone" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Supervisor</b></td>
				<td><input type="text" name="Supervisor" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Job Title</b></td>
				<td><input type="text" name="Job_Title" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Brief Description of Duties</b></td>
				<td><textarea rows="3" name="Description_of_Duties" cols="25"></textarea><br/>
				&nbsp;<input type="radio" value="Paid" name="Pay_Status" checked/>Paid&nbsp;
				<input type="radio" name="Pay_Status" value="Unpaid"/>Unpaid</td>
			</tr>
			<tr>
				<td valign="top"><b>Number of Hours per Week</b></td>
				<td><input type="text" name="Hours_Per_Week" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>College Major</b></td>
				<td><input type="text" name="College_Major" size="20"/></td>
			</tr>
			<tr>
				<td valign="top"><b>Career Goal</b></td>
				<td><input type="text" name="Career_Goal" size="20"/></td>
			</tr>
			<!--
			<tr>
				<td valign="top"><b>Coordinator Request</b></td>
				<td>
				    <select name="Instructor_Requested">
				     <option value="">-- No Preference --</option>
				    <%
				      'Set RS = Server.CreateObject("ADODB.RecordSet")
				      'Set RS = Con.Execute("exec student_InstructorList")
				      
				      'While Not RS.EOF = True
				     
				       '<option><%=RS("Name")%></option>
				     
				      'RS.MoveNext
				      'WEND
				    %>
				    
				    </select><br/>
&nbsp;<font size="2"><b>* Does not guarantee coordinator</b></font></td>
			</tr>
			-->
			<tr>
				<td valign="top" colspan="2">&nbsp;
				</td>
			</tr>
			<tr>
			 <td colspan="2">How many other units (not including work experience) will you be taking during the selected semester?<br/><br/>
			 <div align="center">
			 <select name="AcademicWorkload">
			    <option value="6">less than 7</option>
			 	<option value="7">7</option>
				<option value="8">more than 7</option>
			 </select>
			 </div>
			 <br/>
			 </td>
			</tr>
			<tr>
				<td valign="top" colspan="2">
				By pressing the submit button below, I agree 
				to <!-- read and --> abide by the requirements in the Cooperative Work 
				Experience Education Student Orientation Handbook</td>
			</tr>
		</table>
	</div>
	<p align="center"><input type="submit" value="Submit" name="submit"/><input type="reset" value="Reset" name="B2"/></p>

</form>

<% Case Else %>	
		<ol id="ProgressBar">
		  <li class="complete">Orientation</li>
		  <li>Log In</li>
		  <li>Application</li>
		  <li>Choose a Course</li>
		  <li>Register</li>
		 </ol>
		</div>
       
		
       
		 <div class="rightbox">	
		  <h3>Login</h3>
          <form method="post" action="app.asp">
	  	  <table border="0" cellspacing="3" cellpadding="3" summary="" style="margin:5px;">
	  	  	<% If bad_login = true Then %>
		     <tr>
		      <td colspan="2" style="color:red;font-weight:bold;">Incorrect User ID/PIN combination.</td>
		     </tr>
		   <% End If %>
			<tr>
			  <td>User ID</td>
			  <td><input type="text" name="UserID"/></td>
			</tr>
			<tr>
			  <td>PIN</td>
			  <td><input type="password" name="PIN" maxlength="6"/></td>
			</tr>
			<tr>
				<td align="center" colspan="2">
					<input type="submit" name="submit" value="Log In"/>
				</td>
			</tr>
		  </table>
          </form>	
		 </div>

		 
        <p><b>Congratulations on passing the quiz.</b> Please log in with the form on the right using your myBanWeb login information.</p>
        
        <p>If you cannot remember your StudentID, you can use your Social Security Number in it's place.  If you cannot remember your PIN, you will need to come to campus and speak with the Admissions &amp; Records office to have it reset.  If you are a distance learning student or cannot otherwise come to campus, you may call the registration helpline at 661-395-4301</p>
			
		

<% End Select %>

<!-- #INCLUDE VIRTUAL="/includes/bottom.asp" -->

<%
Function IsBannerID(user_input)
	If Left(user_input, 1) = "@" Then
		IsBannerID = True
	Else
		IsBannerID = False
	End If
End Function

Function FieldsValid(UserID, PIN)

'Check that the User ID and Password aren't null and conform to User ID and PIN requirements.
		If UserID = "" OR PIN = "" Then
			If UserID = "" Then
				invalid_userid = True
			End If
			If PIN = "" Then
				invalid_pin = True
			End If
		Else
			If IsBannerID(UserID) = True Then
				modUserID = Right(UserID, 8)
			Else
				modUserID = UserID
			End If
			If InStrGrp(modUserID, "D") = True OR Len(Trim(UserID)) <> 9 Then
				invalid_userid = True 'Invalid User ID		
			End If
			If InStrGrp(PIN, "D") = True OR Len(Trim(PIN)) > 6 Then
				invalid_pin = True ' Invalid PIN		
			End If
		End If 
		
		If invalid_userid <> True AND invalid_pin <> True Then
			'Set Banner = server.CreateObject("COM_WebServices.Banner")
			'Authenticate passed User ID and PIN to Banner Web Services
			'If Banner.Authenticate(UserID, PIN) = "True" Then
			'	FieldsValid = 1 'Correct & Authenticated
			'Else
			'	FieldsValid = 4 'Incorrect Studnet ID/PIN Combo
			'End If
			'Set Banner = Nothing
			Set oServerXML = CreateObject("Msxml2.ServerXMLHTTP")
            oServerXML.Open "GET", "https://www.url.com/folder1/folder2/webservice.asmx/AuthenticateUser?AccountName=" & UserID & "&Password=" & PIN & "", False
            oServerXML.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
            oServerXML.send
            'response.Write(oServerXML.responsexml.Text)
            if oServerXML.responsexml.Text = "True" then
                FieldsValid = 1 'Correct & Authenticated
            Else
                FieldsValid = 4 'Incorrect Studnet ID/PIN Combo
            end if
		Else
			If invalid_userid = True Then
				FieldsValid = 2 'Invalid Student ID
			End If
			If invalid_pin = True Then
				FieldsValid = 3 'Invalid PIN
			End If
		End If 
		
End Function
%>}