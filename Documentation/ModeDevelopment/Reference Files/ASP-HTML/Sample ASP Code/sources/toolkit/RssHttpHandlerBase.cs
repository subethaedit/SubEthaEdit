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
using System.Xml;

namespace RssToolkit {
    // base class for RssHttpHandler - Generic handler and strongly typed ones are derived from it
    public abstract class RssHttpHandlerBase<RssChannelType, RssItemType, RssImageType> : IHttpHandler
        where RssChannelType : RssChannelBase<RssItemType, RssImageType>, new() 
        where RssItemType : RssElementBase, new() 
        where RssImageType : RssElementBase, new() {

        RssChannelType _channel;
        HttpContext _context;

        protected RssChannelType Channel {
            get { return _channel; }
        }

        protected HttpContext Context {
            get { return _context; }
        }

        // the only method derived classes are supposed to override
        protected virtual void PopulateChannel(string channelName, string userName) {
        }

        void IHttpHandler.ProcessRequest(HttpContext context) {
            _context = context;

            // create the channel
            _channel = new RssChannelType();
            _channel.SetDefaults();

            // parse the channel name and the user name from the query string
            string userName;
            string channelName;
            RssHttpHandlerHelper.ParseChannelQueryString(context.Request, out channelName, out userName);

            // populate items (call the derived class)
            PopulateChannel(channelName, userName);

            // save XML into response
            XmlDocument doc = _channel.SaveAsXml();
            context.Response.ContentType = "text/xml";
            doc.Save(context.Response.OutputStream);
        }

        bool IHttpHandler.IsReusable {
            get { return false; }
        }
    }
}
