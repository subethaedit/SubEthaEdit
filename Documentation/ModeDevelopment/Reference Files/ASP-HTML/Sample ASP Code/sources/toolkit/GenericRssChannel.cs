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
using System.Net;
using System.Text;
using System.Xml;

namespace RssToolkit {
    // Class to consume (or create) a channel in a late-bound way
    public sealed class GenericRssChannel : RssChannelBase<GenericRssElement, GenericRssElement> {
        public GenericRssChannel() {
        }

        public new Dictionary<string, string> Attributes {
            get { return base.Attributes; }
        }

        public string this[string attributeName] {
            get { return GetAttributeValue(attributeName); }
            set { Attributes[attributeName] = value; }
        }

        public GenericRssElement Image {
            get { return GetImage(); }
        }

        public static GenericRssChannel LoadChannel(string url) {
            GenericRssChannel channel = new GenericRssChannel();
            channel.LoadFromUrl(url);
            return channel;
        }

        public static GenericRssChannel LoadChannel(XmlDocument doc) {
            GenericRssChannel channel = new GenericRssChannel();
            channel.LoadFromXml(doc);
            return channel;
        }

        // Select method for programmatic databinding
        public IEnumerable SelectItems() {
            return SelectItems(-1);
        }
         
        public IEnumerable SelectItems(int maxItems) {
            ArrayList data = new ArrayList();

            foreach (GenericRssElement element in Items) {
                if (maxItems > 0 && data.Count >= maxItems) {
                    break;
                }

                data.Add(new RssElementCustomTypeDescriptor(element.Attributes));
            }

            return data;
        }
    }
}
