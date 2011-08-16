<%@ Page Language="VB" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">

</script>

<html xmlns="http://www.w3.org/1999/xhtml" >
<head runat="server">
    <title>Untitled Page</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        <h2>Scenario 2 -- Consuming RSS feed using ObjectDataSource</h2>    
        <asp:DataList ID="DataList1" runat="server" CellPadding="4" DataSourceID="ObjectDataSource1"
            ForeColor="#333333">
            <FooterStyle BackColor="#1C5E55" Font-Bold="True" ForeColor="White" />
            <SelectedItemStyle BackColor="#C5BBAF" Font-Bold="True" ForeColor="#333333" />
            <ItemTemplate>
                <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl='<%# Eval("link") %>' Text='<%# Eval("title") %>'></asp:HyperLink>
            </ItemTemplate>
            <AlternatingItemStyle BackColor="White" />
            <ItemStyle BackColor="#E3EAEB" />
            <HeaderStyle BackColor="#1C5E55" Font-Bold="True" ForeColor="White" />
        </asp:DataList><asp:ObjectDataSource ID="ObjectDataSource1" runat="server" SelectMethod="LoadChannelItems"
            TypeName="MsnbcChannel"></asp:ObjectDataSource>
    
    </div>
    </form>
</body>
</html>
