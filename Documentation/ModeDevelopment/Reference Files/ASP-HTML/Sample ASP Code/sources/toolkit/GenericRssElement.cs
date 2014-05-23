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
    // late-bound RSS element (used for late bound item and image)
    public sealed class GenericRssElement : RssElementBase {
        public GenericRssElement() {
        }

        public new Dictionary<string, string> Attributes {
            get { return base.Attributes; }
        }

        public string this[string attributeName] {
            get { return GetAttributeValue(attributeName); }
            set { Attributes[attributeName] = value; }
        }
    }
}
