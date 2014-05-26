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

namespace RssToolkit {
    // internal representation of parsed RSS channel
    internal class RssChannelDom {
        Dictionary<string, string> _channel;
        Dictionary<string, string> _image;
        List<Dictionary<string, string>> _items;
        DateTime _utcExpiry;

        internal RssChannelDom(Dictionary<string, string> channel,
                                Dictionary<string, string> image,
                                List<Dictionary<string, string>> items) {
            _channel = channel;
            _image = image;
            _items = items;
            _utcExpiry = DateTime.MaxValue;
        }

        internal void SetExpiry(DateTime utcExpiry) {
            _utcExpiry = utcExpiry;
        }

        internal Dictionary<string, string> Channel {
            get { return _channel; }
        }

        internal Dictionary<string, string> Image {
            get { return _image; }
        }

        internal List<Dictionary<string, string>> Items {
            get { return _items; }
        }

        internal DateTime UtcExpiry {
            get { return _utcExpiry; }
        }
    }
}
