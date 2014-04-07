
<%
Dim bgcolor, textcolor
' Get values from form and paste together into 2 - 6 character strings
bgcolor = Request.Form("bg_red") & Request.Form("bg_green") & Request.Form("bg_blue")
textcolor =  Request.Form("text_red") & Request.Form("text_green") & Request.Form("text_blue")

' If the strings aren't 6 characters long then ignore them
' This means that not all the pull downs in the group had values entered
If len(bgcolor) = 6 Then
	bgcolor = " BGCOLOR=#" & bgcolor
Else
	bgcolor = ""
End If

If len(textcolor) = 6 Then#c94b16#d6771c
	textcolor = " COLOR=#" & textcolor
Else
	textcolor = ""
End If

' Now all that's left is to show our colorful message which is mostly just HTML
%>
<TABLE BORDER="1" CELLSPACING="3" CELLPADDING="5"<%= bgcolor %> ff="asdf">
	<TR>
		<TD VALIGN="CENTER"><STRONG><FONT SIZE="6"<%= textcolor %>>What color would you like today?</FONT></STRONG></TD>
	</TR>
</TABLE>

<!-- All the cool stuff is already done...Now we're just building the form -->
<FORM ACTION="colors.asp" METHOD="POST">
<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="3">
<TR>
	<TD>&nbsp;</TD>
	<TD ALIGN="center">Red</TD>
	<TD ALIGN="center">Green</TD>
	<TD ALIGN="center">Blue</TD>
</TR>
<TR>
	<TD>Background Color:</TD>
	<TD>
		<select NAME="bg_red">
			<OPTION><%= Request.Form("bg_red") %></OPTION><OPTION>00</OPTION><OPTION>33</OPTION><OPTION>66</OPTION><OPTION>99</OPTION><OPTION>CC</OPTION><OPTION>FF</OPTION>
		</select>
	</TD>
	<TD>
		<select NAME="bg_green">
			<OPTION><%= Request.Form("bg_green") %></OPTION><OPTION>00</OPTION><OPTION>33</OPTION><OPTION>66</OPTION><OPTION>99</OPTION><OPTION>CC</OPTION><OPTION>FF</OPTION>
		</select>
	</TD>
	<TD>
		<select NAME="bg_blue">
			<OPTION><%= Request.Form("bg_blue") %></OPTION><OPTION>00</OPTION><OPTION>33</OPTION><OPTION>66</OPTION><OPTION>99</OPTION><OPTION>CC</OPTION><OPTION>FF</OPTION>
		</select>
	</TD>
</TR>
<TR>
	<TD>Text Color:</TD>
	<TD>
		<select NAME="text_red">
			<OPTION><%= Request.Form("text_red") %></OPTION><OPTION>00</OPTION><OPTION>33</OPTION><OPTION>66</OPTION><OPTION>99</OPTION><OPTION>CC</OPTION><OPTION>FF</OPTION>
		</select>
	</TD>
	<TD>
		<select NAME="text_green">
			<OPTION><%= Request.Form("text_green") %></OPTION><OPTION>00</OPTION><OPTION>33</OPTION><OPTION>66</OPTION><OPTION>99</OPTION><OPTION>CC</OPTION><OPTION>FF</OPTION>
		</select>
	</TD>
	<TD>
		<select NAME="text_blue">
			<OPTION><%= Request.Form("text_blue") %></OPTION><OPTION>00</OPTION><OPTION>33</OPTION><OPTION>66</OPTION><OPTION>99</OPTION><OPTION>CC</OPTION><OPTION>FF</OPTION>
		</select>
	</TD>
</TR>
</TABLE>
<INPUT TYPE="submit" VALUE="Colorize Me!">
</FORM>