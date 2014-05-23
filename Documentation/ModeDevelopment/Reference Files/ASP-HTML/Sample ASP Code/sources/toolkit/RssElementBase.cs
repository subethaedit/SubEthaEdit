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
    // the base class for all RSS elements (item, image, channel)
    // has collection of attributes
    public abstract class RssElementBase {
        Dictionary<string, string> _attributes = 
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        public RssElementBase() {
        }

        public virtual void SetDefaults() {
        }

        internal void SetAttributes(Dictionary<string, string> attributes) {
            _attributes = attributes;
        }

        protected string GetAttributeValue(string attributeName) {
            string attributeValue;

            if (!_attributes.TryGetValue(attributeName, out attributeValue)) {
                attributeValue = string.Empty;
            }

            return attributeValue;
        }

        protected void SetAttributeValue(string attributeName, string attributeValue) {
            _attributes[attributeName] = attributeValue;
        }

        protected internal Dictionary<string, string> Attributes { 
            get { return _attributes; }
        }
    }
}
