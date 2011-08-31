/*=======================================================================
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
=======================================================================*/

using System;
using System.CodeDom;
using System.CodeDom.Compiler;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.Compilation;
using System.Web.Hosting;
using System.Xml;

namespace RssToolkit {
    // build provider for .rssdl type - to automatically generate strongly typed
    // classes for channels from URLs defined in .rssdl file
    [BuildProviderAppliesTo(BuildProviderAppliesTo.Code)]
    public sealed class RssdlBuildProvider : BuildProvider {

        public override void GenerateCode(AssemblyBuilder assemblyBuilder) {
            
            // load as XML
            XmlDocument doc = new XmlDocument();

            using (Stream s = OpenStream(VirtualPath)) {
                doc.Load(s);
            }

            // valide root rssdl node
            XmlNode root = doc.DocumentElement;

            if (root.Name != "rssdl") {
                throw new InvalidDataException(
                    string.Format("Unexpected root node '{0}' -- expected root 'rssdl' node", root.Name));
            }

            // iterate through rss nodes
            for (XmlNode n = root.FirstChild; n != null; n = n.NextSibling) {
                if (n.NodeType != XmlNodeType.Element) {
                    continue;
                }

                if (n.Name != "rss") {
                    throw new InvalidDataException(
                        string.Format("Unexpected node '{0}' -- expected root 'rss' node", root.Name));
                }

                string name = string.Empty;
                string file = string.Empty;
                string url = string.Empty;
                string ns = string.Empty;

                foreach (XmlAttribute attr in n.Attributes) {
                    switch (attr.Name) {
                        case "name":
                            name = attr.Value;
                            break;
                        case "url":
                            if (!string.IsNullOrEmpty(file)) {
                                throw new InvalidDataException("Only one of 'file' and 'url' can be specified");
                            }

                            url = attr.Value;
                            break;
                        case "file":
                            if (!string.IsNullOrEmpty(url)) {
                                throw new InvalidDataException("Only one of 'file' and 'url' can be specified");
                            }

                            file = VirtualPathUtility.Combine(VirtualPathUtility.GetDirectory(VirtualPath), attr.Value);
                            break;
                        case "namespace":
                            ns = attr.Value;
                            break;
                        default:
                            throw new InvalidDataException(
                                string.Format("Unexpected attribute '{0}'", attr.Name));
                    }
                }

                if (string.IsNullOrEmpty(name)) {
                    throw new InvalidDataException("Missing 'name' attribute");
                }

                if (string.IsNullOrEmpty(url) && string.IsNullOrEmpty(file)) {
                    throw new InvalidDataException("Missing 'url' or 'file' attribute - one must be specified");
                }

                // load channel
                GenericRssChannel channel = null;

                if (!string.IsNullOrEmpty(url)) {
                    channel = GenericRssChannel.LoadChannel(url);
                }
                else {
                    XmlDocument rssDoc = new XmlDocument();

                    using (Stream s = OpenStream(file)) {
                        rssDoc.Load(s);
                    }

                    channel = GenericRssChannel.LoadChannel(rssDoc);
                }

                // compile channel
                CodeCompileUnit ccu = new CodeCompileUnit();
                RssCodeGenerator.GenerateCodeDomTree(channel, ns, name, ccu);
                assemblyBuilder.AddCodeCompileUnit(this, ccu);
            }
        }
    }
}
