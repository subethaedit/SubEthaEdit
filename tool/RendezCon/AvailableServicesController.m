//
//  AvailableServicesController.m
//  RendezCon
//
//  Created by Dominik Wagner on Mon Dec 22 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "AvailableServicesController.h"


@implementation AvailableServicesController

-(void)dealloc {
    [I_browser stop];
    [I_browser setDelegate:nil];
    [I_browser release];
    [super dealloc];
}

-(void) awakeFromNib {
    [I_tableView setTarget:self];
    [I_tableView setDoubleAction:@selector(addServiceToBrowseFor:)];
    I_browser=[NSNetServiceBrowser new];
    [I_browser setDelegate:self];
    [I_browser searchForServicesOfType:@"_services._mdns._udp." inDomain:@""];
    // IB forbids utility windows to not hide on deactivate. screw him.
    [I_panel setHidesOnDeactivate:NO];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
           didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSDictionary *entry=[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@.%@",[aNetService name],[aNetService type]] forKey:@"serviceType"];
    [I_availableServicesArrayController addObject:entry];
}


@end
