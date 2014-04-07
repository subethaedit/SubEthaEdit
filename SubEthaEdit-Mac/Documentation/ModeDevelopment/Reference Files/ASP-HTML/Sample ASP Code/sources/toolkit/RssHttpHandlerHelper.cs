/*=======================================================================
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
=======================================================================*/

using System;
using System.Collections.Generic;
using System.Text;
using System.Web;
using System.Web.Security;

namespace RssToolkit {
    // helper class (for RssHtppHandler) to pack and unpack user name and channel to from/to query string
    public class RssHttpHandlerHelper {
        private RssHttpHandlerHelper() {
        }

        // helper to generate link [to the .ashx] containing channel name and (encoded) userName
        public static string GenerateChannelLink(string handlerPath, string channelName, string userName) {
            string link = VirtualPathUtility.ToAbsolute(handlerPath);

            if (string.IsNullOrEmpty(userName)) {
                if (!string.IsNullOrEmpty(channelName)) {
                    link += "?c=" + HttpUtility.UrlEncodeUnicode(channelName);
                }
            }
            else {
                if (channelName == null) {
                    channelName = string.Empty;
                }

                userName = "." + userName; // not to confuse the encrypted string with real auth ticket for real user
                DateTime ticketDate = DateTime.Now.AddDays(-100); // already expried

                FormsAuthenticationTicket t = new FormsAuthenticationTicket(
                    2, userName, ticketDate, ticketDate.AddDays(2), false, channelName, "/");

                link += "?t=" + FormsAuthentication.Encrypt(t);
            }

            return link;
        }

        internal static void ParseChannelQueryString(HttpRequest request,
            out string channelName, out string userName) {

            string ticket = request.QueryString["t"];

            if (string.IsNullOrEmpty(ticket)) {
                userName = string.Empty;
                // optional unencrypted channel name
                channelName = request.QueryString["c"];
            }
            else {
                // encrypted user name and channel name
                FormsAuthenticationTicket t = FormsAuthentication.Decrypt(ticket);
                userName = t.Name.Substring(1); // remove extra prepended '.'
                channelName = t.UserData;
            }
        }
    }
}
