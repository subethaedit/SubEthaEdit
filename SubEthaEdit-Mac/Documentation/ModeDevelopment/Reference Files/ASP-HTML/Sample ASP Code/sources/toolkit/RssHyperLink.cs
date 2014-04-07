/*=======================================================================
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
=======================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.Design;
using System.Web.UI.WebControls;
using System.Windows.Forms;
using System.Windows.Forms.Design;

namespace RssToolkit {
    // RssHyperLink control - works with RssHttpHandler
    public class RssHyperLink : HyperLink {
        string _channelName;
        bool _includeUserName;

        public RssHyperLink() {
            Text = "RSS";
        }

        // passed to RssHttpHandler
        public string ChannelName {
            get { return _channelName; }
            set { _channelName = value; }
        }

        // when flag is set, the current user'd name is passed to RssHttpHandler
        public bool IncludeUserName {
            get { return _includeUserName; }
            set { _includeUserName = value; }
        }

        protected override void OnPreRender(EventArgs e) {
            // modify the NavigateUrl to include optional user name and channel name
            string channel = _channelName != null ? _channelName : string.Empty;
            string user = _includeUserName ? Context.User.Identity.Name : string.Empty;
            NavigateUrl = RssHttpHandlerHelper.GenerateChannelLink(NavigateUrl, channel, user);

            // add <link> to <head> tag (if <head runat=server> is present)
            if (Page.Header != null) {
                string title = string.IsNullOrEmpty(channel) ? Text : channel;

                Page.Header.Controls.Add(new LiteralControl(string.Format(
                    "\r\n<link rel=\"alternate\" type=\"application/rss+xml\" title=\"{0}\" href=\"{1}\" />", 
                    title, NavigateUrl)));
            }

            base.OnPreRender(e);
        }
    }
}
