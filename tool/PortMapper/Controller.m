#import "Controller.h"
#import "PortMapper.h"

@implementation Controller

- (void) awakeFromNib {

}



- (BOOL) probePort: (int) portNumber
{
    NSURLRequest * portProbeRequest = [NSURLRequest requestWithURL: [NSURL URLWithString:
                                [NSString stringWithFormat: @"https://www.grc.com/x/portprobe=%d", portNumber]]
                                cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 15.0];
    
    
    NSURLResponse *response;
    NSData *shieldsUpData = [NSURLConnection sendSynchronousRequest:portProbeRequest returningResponse:&response error:nil];

    NSXMLDocument * shieldsUpProbe = [[NSXMLDocument alloc] initWithData: shieldsUpData options: NSXMLDocumentTidyHTML error: nil];
    
    if (shieldsUpProbe)
    {
        NSArray * nodes = [shieldsUpProbe nodesForXPath: @"/html/body/center/table[3]/tr/td[2]" error: nil];
        if ([nodes count] != 1)
        {
            NSArray * title = [shieldsUpProbe nodesForXPath: @"/html/head/title" error: nil];
            // This may happen when we probe twice too quickly
            if ([title count] != 1 || ![[[title objectAtIndex: 0] stringValue] isEqualToString:
                                                                    @"NanoProbe System Already In Use"])
            {
                NSLog(@"Unable to get port status: invalid (outdated) XPath expression");
                [[shieldsUpProbe XMLData] writeToFile: @"/tmp/shieldsUpProbe.html" atomically: YES];
            }
        }
        else
        {
            NSString * portStatus = [[[[nodes objectAtIndex: 0] stringValue] stringByTrimmingCharactersInSet:   [[NSCharacterSet letterCharacterSet] invertedSet]] lowercaseString];
            
            if ([portStatus isEqualToString: @"open"])
                [statusTextField setStringValue:@"Port is open"];
            else if ([portStatus isEqualToString: @"stealth"])
                [statusTextField setStringValue:@"Port is stealth"];
            else if ([portStatus isEqualToString: @"closed"])
                [statusTextField setStringValue:@"Port is closed"];
            else
            {
                NSLog(@"Unable to get port status: unknown port state");
            }
        }
    }
    else
    {
        NSLog(@"Unable to get port status: failed to create xml document");
    }
    
}

- (IBAction) map:(id)sender {
    [statusTextField setStringValue:@"Mapping port..."];
    PortMapper *pm = [PortMapper sharedInstance];
    [pm mapPort:[portTextField intValue]];
    [statusTextField setStringValue:@"Ready."];
}

- (IBAction) check:(id)sender {
    [statusTextField setStringValue:@"Checking port..."];
    [self probePort:[portTextField intValue]];
}


@end
