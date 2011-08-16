using System;
using System.Data;
using System.Configuration;
using System.Collections;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;

using RssToolkit;

public partial class scenario4 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        GenericRssChannel c = GenericRssChannel.LoadChannel("http://rss.msnbc.msn.com/id/3032091/device/rss/rss.xml");

        Image1.ImageUrl = c.Image["url"];

        GridView1.DataSource = c.SelectItems();
        GridView1.DataBind();
    }
}
