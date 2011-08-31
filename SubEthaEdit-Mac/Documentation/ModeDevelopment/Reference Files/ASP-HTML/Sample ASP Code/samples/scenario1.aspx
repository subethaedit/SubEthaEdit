<%@ Page Language="VB"%>

<%@ Register Assembly="RssToolkit, Version=1.0.0.1, Culture=neutral, PublicKeyToken=02e47a85b237026a"
    Namespace="RssToolkit" TagPrefix="cc1" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!-- #include file="blah"  -->


<script runat="server">

</script>


<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <h2>Scenario 1 -- Consuming RSS feed using RssDataSource</h2>    
        <asp:DataList ID="DataList1<%%>" runat="server" CellPadding="4" DataSourceID="RssDataSource1"
            ForeColor="#333333">
            <FooterStyle BackColor="#1C5E55" Font-Bold="True" ForeColor="White" />
            <SelectedItemStyle BackColor="#C5BBAF" Font-Bold="True" ForeColor="#333333" />
            <ItemTemplate>
                <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("link") %>' Text='<%# Eval("title") %>'></asp:HyperLink>
            </ItemTemplate>
            <AlternatingItemStyle BackColor="White" />
            <ItemStyle BackColor="#E3EAEB" />
            <HeaderStyle BackColor="#1C5E55" Font-Bold="True" ForeColor="White" />
        </asp:DataList><cc1:rssdatasource id="RssDataSource1" runat="server" url="http://rss.msnbc.msn.com/id/3032091/device/rss/rss.xml" MaxItems="0"></cc1:rssdatasource>
    
    </div>
    </form>
</body>
</html>
