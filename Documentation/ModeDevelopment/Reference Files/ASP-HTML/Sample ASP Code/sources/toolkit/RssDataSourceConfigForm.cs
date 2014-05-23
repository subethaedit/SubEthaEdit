/*=======================================================================
  Copyright (C) Microsoft Corporation.  All rights reserved.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
  KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
=======================================================================*/

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace RssToolkit {
    // WinForm dialog to configure RSS data source
    public partial class RssDataSourceConfigForm : Form {
        RssDataSource _dataSource;

        static List<string> _history = new List<string>();

        void AddToHistory(string url) {
            if (string.IsNullOrEmpty(url)) {
                return;
            }

            lock (_history) {
                foreach (string s in _history) {
                    if (url == s) {
                        return;
                    }
                }

                _history.Insert(0, url);
            }
        }

        public RssDataSourceConfigForm(RssDataSource dataSource) {
            _dataSource = dataSource;
            InitializeComponent();

            AddToHistory(dataSource.Url);

            lock (_history) {
                foreach (string url in _history) {
                    urlComboBox.Items.Add(url);
                }
            }

            urlComboBox.Text = dataSource.Url;
        }

        private void button1_Click(object sender, EventArgs e) {
            string url = urlComboBox.Text;

            if (url != _dataSource.Url) {
                try {
                    // validate URL
                    GenericRssChannel.LoadChannel(url);
                    AddToHistory(url);
                }
                catch {
                    MessageBox.Show(this, "Failed to load RSS feed for the specified URL", "RssDataSource Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }

            _dataSource.Url = url;
            DialogResult = DialogResult.OK;
        }
    }
}