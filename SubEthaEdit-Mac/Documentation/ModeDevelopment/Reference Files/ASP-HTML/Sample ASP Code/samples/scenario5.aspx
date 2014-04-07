<%@ Page Language="C#" %>

<%@ Register Assembly="RssToolkit, Version=1.0.0.1, Culture=neutral, PublicKeyToken=02e47a85b237026a"
    Namespace="RssToolkit" TagPrefix="cc1" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">

</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <h2>Scenario 5 -- Publishing RSS feed using strongly typed classes</h2>
    <form id="form1" runat="server">
    <div>
        Simple feed:
        <cc1:rsshyperlink id="RssHyperLink1" runat="server" includeusername="False" navigateurl="~/scenario5.ashx">RSS</cc1:rsshyperlink><br />
        Feed with channel name:<cc1:RssHyperLink ID="RssHyperLink2" runat="server" ChannelName="Channel1" IncludeUserName="False" NavigateUrl="~/scenario5.ashx">RSS Channel1</cc1:RssHyperLink><br />
        Feed with channel name:
        <cc1:RssHyperLink ID="RssHyperLink3" runat="server" ChannelName="Channel2" IncludeUserName="False"
            NavigateUrl="~/scenario5.ashx">RSS Channel2</cc1:RssHyperLink><br />
        Feed for the particular user:
        <cc1:RssHyperLink ID="Rsshyperlink4" runat="server" IncludeUserName="True" NavigateUrl="~/scenario5.ashx">RSS</cc1:RssHyperLink></div>
    </form>
</body>
</html>
