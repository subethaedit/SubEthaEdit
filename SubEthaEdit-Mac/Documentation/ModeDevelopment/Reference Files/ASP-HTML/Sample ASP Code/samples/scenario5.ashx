<%@ WebHandler Language="C#" Class="scenario5" %>

using System;
using System.Web;

public class scenario5 : Sample5HttpHandlerBase {
    protected override void PopulateChannel(string channelName, string userName) {
        Channel.Name = channelName;
        Channel.User = userName;

        if (!string.IsNullOrEmpty(channelName)) {
            Channel.Title += " '" + channelName + "'";
        }

        if (!string.IsNullOrEmpty(userName)) {
            Channel.Title += " (generated for " + userName + ")";
        }


        Channel.Items.Add(
            new Sample5Item("Scenario1", 
                            "Consuming RSS feed using RssDataSource",
                            "~/scenario1.aspx"));
        Channel.Items.Add(
            new Sample5Item("Scenario2",
                            "Consuming RSS feed using ObjectDataSource",
                            "~/scenario2.aspx"));
        Channel.Items.Add(
            new Sample5Item("Scenario3",
                            "Consuming RSS feed programmatically using strongly typed classes",
                            "~/scenario3.aspx"));
        Channel.Items.Add(
            new Sample5Item("Scenario4",
                            "Consuming RSS feed programmatically using late bound classes",
                            "~/scenario4.aspx"));
    }    
}