/*=======================================================================
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
=======================================================================*/

using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Hosting;
using System.Xml;

namespace RssToolkit {
    // helper class that provides memory and disk caching of the downloaded feeds
    internal class RssDownloadManager {
        static RssDownloadManager _theManager = new RssDownloadManager();

        Dictionary<string, RssChannelDom> _cache;
        int _defaultTtlMinutes;
        string _directoryOnDisk;

        private RssDownloadManager() {
            // create in-memory cache
            _cache = new Dictionary<string, RssChannelDom>();

            // get default ttl value from config
            _defaultTtlMinutes = GetTtlFromString(ConfigurationManager.AppSettings["defaultRssTtl"], 1);

            // prepare disk directory
            _directoryOnDisk = PrepareTempDir();
        }

        RssChannelDom DownloadChannelDom(string url) {
            // look for disk cache first
            RssChannelDom dom = TryLoadFromDisk(url);

            if (dom != null) {
                return dom;
            }

            // download the feed
            byte[] feed = new WebClient().DownloadData(url);

            // parse it as XML
            XmlDocument doc = new XmlDocument();
            doc.Load(new MemoryStream(feed));

            // parse into DOM
            dom = RssXmlHelper.ParseChannelXml(doc);

            // set expiry
            string ttlString = null;
            dom.Channel.TryGetValue("ttl", out ttlString);
            int ttlMinutes = GetTtlFromString(ttlString, _defaultTtlMinutes);
            DateTime utcExpiry = DateTime.UtcNow.AddMinutes(ttlMinutes);
            dom.SetExpiry(utcExpiry);

            // save to disk
            TrySaveToDisk(doc, url, utcExpiry);

            return dom;
        }

        RssChannelDom TryLoadFromDisk(string url) {
            if (_directoryOnDisk == null) {
                return null; // no place to cache
            }

            // look for all files matching the prefix
            // looking for the one matching url that is not expired
            // removing expired (or invalid) ones
            string pattern = GetTempFileNamePrefixFromUrl(url) + "_*.rss";
            string[] files = Directory.GetFiles(_directoryOnDisk, pattern, SearchOption.TopDirectoryOnly);

            foreach (string rssFilename in files) {
                XmlDocument rssDoc = null;
                bool isRssFileValid = false;
                DateTime utcExpiryFromRssFile = DateTime.MinValue;
                string urlFromRssFile = null;

                try {
                    rssDoc = new XmlDocument();
                    rssDoc.Load(rssFilename);

                    // look for special XML comment (before the root tag)'
                    // containing expiration and url
                    XmlComment comment = rssDoc.DocumentElement.PreviousSibling as XmlComment;

                    if (comment != null) {
                        string c = comment.Value;
                        int i = c.IndexOf('@');
                        long expiry;

                        if (long.TryParse(c.Substring(0, i), out expiry)) {
                            utcExpiryFromRssFile = DateTime.FromBinary(expiry);
                            urlFromRssFile = c.Substring(i+1);
                            isRssFileValid = true;
                        }
                    }
                }
                catch {
                    // error processing one file shouldn't stop processing other files
                }

                // remove invalid or expired file
                if (!isRssFileValid || utcExpiryFromRssFile < DateTime.UtcNow) {
                    try {
                        File.Delete(rssFilename);
                    }
                    catch {
                    }

                    // try next file
                    continue;
                }

                // match url
                if (urlFromRssFile == url) {
                    // found a good one - create DOM and set expiry (as found on disk)
                    RssChannelDom dom = RssXmlHelper.ParseChannelXml(rssDoc);
                    dom.SetExpiry(utcExpiryFromRssFile);
                    return dom;
                }
            }

            // not found
            return null;
        }

        void TrySaveToDisk(XmlDocument doc, string url, DateTime utcExpiry) {
            if (_directoryOnDisk == null) {
                return;
            }

            doc.InsertBefore(doc.CreateComment(string.Format(
                "{0}@{1}", utcExpiry.ToBinary(), url
                )), doc.DocumentElement);

            string fileName = string.Format("{0}_{1:x8}.rss",
                GetTempFileNamePrefixFromUrl(url),
                Guid.NewGuid().ToString().GetHashCode());

            try {
                doc.Save(Path.Combine(_directoryOnDisk, fileName));
            }
            catch {
                // can't save to disk - not a problem
            }
        }

        RssChannelDom GetChannelDom(string url) {
            RssChannelDom dom = null;

            lock (_cache) {
                if (_cache.TryGetValue(url, out dom)) {
                    if (DateTime.UtcNow > dom.UtcExpiry) {
                        _cache.Remove(url);
                        dom = null;
                    }
                }
            }

            if (dom == null) {
                dom = DownloadChannelDom(url);

                lock (_cache) {
                    _cache[url] = dom;
                }
            }

            return dom;
        }

        public static RssChannelDom GetChannel(string url) {
            return _theManager.GetChannelDom(url);
        }

        static int GetTtlFromString(string ttlString, int defaultTtlMinutes) {
            if (!string.IsNullOrEmpty(ttlString)) {
                int ttlMinutes;
                if (int.TryParse(ttlString, out ttlMinutes)) {
                    if (ttlMinutes >= 0) {
                        return ttlMinutes;
                    }
                }
            }

            return defaultTtlMinutes;
        }

        static string PrepareTempDir() {
            string tempDir = null;

            try {
                string d = ConfigurationManager.AppSettings["rssTempDir"];

                if (string.IsNullOrEmpty(d)) {
                    if (HostingEnvironment.IsHosted) {
                        d = HttpRuntime.CodegenDir;
                    }
                    else {
                        d = Environment.GetEnvironmentVariable("TEMP");

                        if (string.IsNullOrEmpty(d)) {
                            d = Environment.GetEnvironmentVariable("TMP");

                            if (string.IsNullOrEmpty(d)) {
                                d = Directory.GetCurrentDirectory();
                            }
                        }
                    }

                    d = Path.Combine(d, "rss");
                }

                if (!Directory.Exists(d)) {
                    Directory.CreateDirectory(d);
                }

                tempDir = d;
            }
            catch {
                // don't cache on disk if can't do it
            }

            return tempDir;
        }

        static string GetTempFileNamePrefixFromUrl(string url) {
            try {
                Uri uri = new Uri(url);
                return string.Format("{0}_{1:x8}", 
                    uri.Host.Replace('.', '_'), uri.AbsolutePath.GetHashCode());
            }
            catch {
                return "rss";
            }
        }
    }
}
