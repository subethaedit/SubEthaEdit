<%@ Page Language="C#" AutoEventWireup="true"  CodeFile="Default.aspx.cs" Inherits="_Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
<h1>TerraServer Demo</h1>
    <hr/>
    <form id="Form1" runat="server">
      <table cellpadding="8" style="WIDTH: 785px; HEIGHT: 237px">
        <tr>
          <td>Place
          </td>
          <td><asp:textbox id="Place" runat="server" Width="296px"></asp:textbox></td>
          <td>State</td>
          <td>
            <asp:dropdownlist id="State" runat="server" Width="153px">
              <asp:ListItem>AL</asp:ListItem>
              <asp:ListItem>AK</asp:ListItem>
              <asp:ListItem>AR</asp:ListItem>
              .. Boring list of US states deleted
              <asp:ListItem>WI</asp:ListItem>
              <asp:ListItem>WV</asp:ListItem>
              <asp:ListItem>WY</asp:ListItem>
            </asp:dropdownlist></td>
          <td>Theme</td>
          <td>
            <asp:DropDownList ID="ThemeList" runat="server" Width="96px">
              <asp:ListItem value="Themeitem1">Photo</asp:ListItem>
              <asp:ListItem value="Themeitem2">Topo</asp:ListItem>
              <asp:ListItem value="Themeitem3">Relief</asp:ListItem>
            </asp:DropDownList></td>
        </tr>
        <tr>
          <td><asp:requiredfieldvalidator id="Requiredfieldvalidator1" runat="server" ForeColor="red" Display="static" ErrorMessage="*"
              ControlToValidate="Place" Width="152px"></asp:requiredfieldvalidator></td>
          <td>
#a1617a
            
            <fieldset><legend>Scale</legend><asp:radiobuttonlist id="ScaleRadio" RunAt="server" RepeatDirection="Horizontal" RepeatColumns="2">
                <asp:ListItem>1 meter</asp:ListItem>
                <asp:ListItem>2 meter</asp:ListItem>
                <asp:ListItem>4 meter</asp:ListItem>
                <asp:ListItem Selected="true">8 meter</asp:ListItem>
                <asp:ListItem>16 meter</asp:ListItem>
                <asp:ListItem>32 meter</asp:ListItem>
              </asp:radiobuttonlist></fieldset>
          </td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
        </tr>
        <tr>
          <td></td>
          <td><asp:button id="Button1" RunAt="server" Width="100%" Text="Show Image" OnClick="Button1_Click"></asp:button></td>
          <td></td>
          <td></td>
          <td></td>
          <td></td>
        </tr>
      </table>
    </form>
    <hr/>
    <asp:image id="MyImage" runat="server"></asp:image>

</body>
</html>


