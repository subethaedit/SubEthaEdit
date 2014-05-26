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

public partial class scenario3 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        MsnbcChannel c = MsnbcChannel.LoadChannel();
        
        Image1.ImageUrl = c.Image.Url;

        GridView1.DataSource = c.Items;
        GridView1.DataBind();
    }
}
