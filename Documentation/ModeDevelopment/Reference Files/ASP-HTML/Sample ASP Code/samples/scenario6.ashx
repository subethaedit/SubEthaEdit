<%@ WebHandler Language="C#" Class="scenario6" %>

using System;
using System.Web;
using RssToolkit;

public class scenario6 : GenericRssHttpHandlerBase {
    protected override void PopulateChannel(string channelName, string userName) {
        Channel["title"] = "Sample Channel";

        if (!string.IsNullOrEmpty(channelName)) {
            Channel["title"] += " '" + channelName + "'";
        }

        if (!string.IsNullOrEmpty(userName)) {
            Channel["title"] += " (generated for " + userName + ")";
        }

        Channel["link"] = "~/scenario6.aspx";
        Channel["description"] = "Channel For Scenario6 in ASP.NET RSS Toolkit samples.";
        Channel["ttl"] = "10";
        Channel["name"] = channelName;
        Channel["user"] = userName;

        GenericRssElement item;

        item = new GenericRssElement();
        item["title"] = "Scenario1";
        item["description"] = "Consuming RSS feed using RssDataSource";
        item["link"] = "~/scenario1.aspx";
        Channel.Items.Add(item);

        item = new GenericRssElement();
        item["title"] = "Scenario2";
        item["description"] = "Consuming RSS feed using ObjectDataSource";
        item["link"] = "~/scenario2.aspx";
        Channel.Items.Add(item);

        item = new GenericRssElement();
        item["title"] = "Scenario3";
        item["description"] = "Consuming RSS feed programmatically using strongly typed classes";
        item["link"] = "~/scenario3.aspx";
        Channel.Items.Add(item);

        item = new GenericRssElement();
        item["title"] = "Scenario4";
        item["description"] = "Consuming RSS feed programmatically using late bound classes";
        item["link"] = "~/scenario4.aspx";
        Channel.Items.Add(item);
    }
}