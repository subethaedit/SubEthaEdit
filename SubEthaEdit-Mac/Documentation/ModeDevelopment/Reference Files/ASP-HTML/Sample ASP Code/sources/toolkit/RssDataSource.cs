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
using System.ComponentModel;
using System.Data;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.Design;
using System.Web.UI.WebControls;
using System.Windows.Forms;
using System.Windows.Forms.Design;

namespace RssToolkit {
    // RSS data source control implementation, including the designer
    [Designer(typeof(RssDataSourceDesigner))]
    [DefaultProperty("Url")]
    public class RssDataSource : DataSourceControl {
        int _maxItems;
        string _url;
        RssDataSourceView _itemsView;
        GenericRssChannel _channel;

        public RssDataSource() {
        }

        protected override DataSourceView GetView(string viewName) {
            if (_itemsView == null) {
                _itemsView = new RssDataSourceView(this, viewName);
            }

            return _itemsView;
        }

        public GenericRssChannel Channel  {
            get {
                if (_channel == null) {
                    if (string.IsNullOrEmpty(_url)) {
                        _channel = new GenericRssChannel();
                    }
                    else {
                        _channel = GenericRssChannel.LoadChannel(_url);
                    }
                }

                return _channel;
            }
        }

        public int MaxItems {
            get { return _maxItems; }
            set { _maxItems = value; }
        }

        public string Url {
            get { return _url; }

            set {
                _channel = null;
                _url = value;
            }
        }
    }

    public class RssDataSourceView : DataSourceView {
        RssDataSource _owner;

        internal RssDataSourceView(RssDataSource owner, string viewName) : base(owner, viewName) {
            _owner = owner;
        }

        public override void Select(DataSourceSelectArguments arguments, DataSourceViewSelectCallback callback) {
            callback(ExecuteSelect(arguments));
        }

        protected override IEnumerable ExecuteSelect(DataSourceSelectArguments arguments) {
            return _owner.Channel.SelectItems(_owner.MaxItems);
        }
    }

    public class RssDataSourceDesigner : DataSourceDesigner {
        RssDataSource _dataSource;
        RssDesignerDataSourceView _view;

        public override void Initialize(IComponent component) {
            base.Initialize(component);
            _dataSource = (RssDataSource)component;
        }

        public override bool CanConfigure {
            get { return true; }
        }

        public override void Configure() {
            InvokeTransactedChange(Component, new TransactedChangeCallback(ConfigureRssDataSource), null, "Configure Data Source");
        }

        private bool ConfigureRssDataSource(object context) {
            try {
                SuppressDataSourceEvents();

                string oldUrl = _dataSource.Url;

                RssDataSourceConfigForm form = new RssDataSourceConfigForm(_dataSource);
                IUIService uiService = (IUIService)GetService(typeof(IUIService));
                DialogResult result = uiService.ShowDialog(form);

                if (result == DialogResult.OK && oldUrl != _dataSource.Url) {
                    OnSchemaRefreshed(EventArgs.Empty);
                }

                return (result == DialogResult.OK);
            }
            finally {
                ResumeDataSourceEvents();
            }
        }

        public override DesignerDataSourceView GetView(string viewName) {
            if (_view == null) {
                _view = new RssDesignerDataSourceView(this, viewName);
            }

            return _view;
        }

        class RssDesignerDataSourceView : DesignerDataSourceView {
            RssDataSourceDesigner _owner;

            public RssDesignerDataSourceView(RssDataSourceDesigner owner, string viewName) 
                : base(owner, viewName) {
                _owner = owner;
            }

            public override IDataSourceViewSchema Schema {
                get {
                    GenericRssChannel channel = _owner._dataSource.Channel;

                    if (channel.Items.Count == 0) {
                        return base.Schema;
                    }

                    Dictionary<string, string> itemAttributes = channel.Items[0].Attributes;

                    // create a datatable and infer schema from there

                    DataTable dt = new DataTable("items");

                    foreach(KeyValuePair<string, string> a in itemAttributes) {
                        dt.Columns.Add(a.Key);
                    }

                    return new DataSetViewSchema(dt);
                }
            }
        }
    }
}
