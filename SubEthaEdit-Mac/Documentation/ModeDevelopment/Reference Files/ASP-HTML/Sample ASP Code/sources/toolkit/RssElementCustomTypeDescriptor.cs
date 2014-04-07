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
using System.Text;

namespace RssToolkit {
    // helper class to enable the data binding logic generate column names at runtime
    class RssElementCustomTypeDescriptor : ICustomTypeDescriptor {
        Dictionary<string, string> _attributes;

        public RssElementCustomTypeDescriptor(Dictionary<string, string> attributes) {
            _attributes = attributes;
        }

        class RssElementCustomPropertyDescriptor : PropertyDescriptor {

            public RssElementCustomPropertyDescriptor(string propertyName)
                : base(propertyName, null) {
            }

            public override Type ComponentType {
                get { return typeof(RssElementCustomTypeDescriptor); } 
            }

            public override bool IsReadOnly {
                get { return true; } 
            }

            public override Type PropertyType { 
                get { return typeof(string); } 
            }

            public override bool CanResetValue(object o) {
                return false; 
            }

            public override void ResetValue(object o) {
            }

            public override void SetValue(object o, object value) {
            }

            public override bool ShouldSerializeValue(object o) { 
                return true; 
            }

            public override object GetValue(object o) {
                RssElementCustomTypeDescriptor element = o as RssElementCustomTypeDescriptor;

                if (element != null) {
                    string propertyValue;

                    if (element._attributes.TryGetValue(Name, out propertyValue)) {
                        return propertyValue;
                    }
                }

                return string.Empty;
            }
        }

        AttributeCollection ICustomTypeDescriptor.GetAttributes() {
            return AttributeCollection.Empty; 
        }

        string ICustomTypeDescriptor.GetClassName() {
            return GetType().Name; 
        }

        string ICustomTypeDescriptor.GetComponentName() {
            return null; 
        }

        TypeConverter ICustomTypeDescriptor.GetConverter() {
            return null; 
        }

        EventDescriptor ICustomTypeDescriptor.GetDefaultEvent() {
            return null; 
        }

        PropertyDescriptor ICustomTypeDescriptor.GetDefaultProperty() { 
            return null; 
        }

        object ICustomTypeDescriptor.GetEditor(Type editorBaseType) {
            return null; 
        }

        EventDescriptorCollection ICustomTypeDescriptor.GetEvents(Attribute[] attributes) {
            return null; 
        }

        EventDescriptorCollection ICustomTypeDescriptor.GetEvents() {
            return null; 
        }

        PropertyDescriptorCollection ICustomTypeDescriptor.GetProperties(Attribute[] attributes) {
            return GetPropertyDescriptors();
        }

        PropertyDescriptorCollection ICustomTypeDescriptor.GetProperties() {
            return GetPropertyDescriptors();
        }

        object ICustomTypeDescriptor.GetPropertyOwner(PropertyDescriptor pd) {
            return (pd is RssElementCustomPropertyDescriptor) ? this : null;
        }

        PropertyDescriptorCollection GetPropertyDescriptors() {
            PropertyDescriptor[] propertyDescriptors = new PropertyDescriptor[_attributes.Count];
            int i = 0;

            foreach (KeyValuePair<string, string> a in _attributes) {
                propertyDescriptors[i++] = new RssElementCustomPropertyDescriptor(a.Key);
            }

            return new PropertyDescriptorCollection(propertyDescriptors);
        }
    }
}
