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
using System.Xml;

namespace RssToolkit {
    // base class for RSS channel (for strongly-typed and late-bound channel types)
    public abstract class RssChannelBase<RssItemType, RssImageType> : RssElementBase
        where RssItemType : RssElementBase, new() 
        where RssImageType : RssElementBase, new() {

        string _url;
        List<RssItemType> _items = new List<RssItemType>();
        RssImageType _image;

        public RssChannelBase() {
        }

        protected void LoadFromUrl(string url) {
            // download the feed
            RssChannelDom dom = RssDownloadManager.GetChannel(url);

            // create the channel
            LoadFromDom(dom);

            // remember the url
            _url = url;
        }

        protected void LoadFromXml(XmlDocument doc) {
            // parse XML
            RssChannelDom dom = RssXmlHelper.ParseChannelXml(doc);

            // create the channel
            LoadFromDom(dom);
        }

        internal void LoadFromDom(RssChannelDom dom) {
            // channel attributes
            SetAttributes(dom.Channel);

            // image attributes
            if (dom.Image != null) {
                RssImageType image = new RssImageType();
                image.SetAttributes(dom.Image);
                _image = image;
            }

            // items
            foreach (Dictionary<string,string> i in dom.Items) {
                RssItemType item = new RssItemType();
                item.SetAttributes(i);
                _items.Add(item);
            }
        }

        internal XmlDocument SaveAsXml() {
            XmlDocument doc = RssXmlHelper.CreateEmptyRssXml();
            XmlNode channelNode = RssXmlHelper.SaveRssElementAsXml(doc.DocumentElement, this, "channel");

            if (_image != null) {
                RssXmlHelper.SaveRssElementAsXml(channelNode, _image, "image");
            }

            foreach (RssItemType item in _items) {
                RssXmlHelper.SaveRssElementAsXml(channelNode, item, "item");
            }

            return doc;
        }

        public List<RssItemType> Items {
            get { return _items; }
        }

        protected RssImageType GetImage() {
            if (_image == null) {
                _image = new RssImageType();
            }

            return _image;
        }

        internal string Url {
            get { return _url; }
        }
    }
}
