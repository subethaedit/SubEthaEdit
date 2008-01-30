//
//  AppController.m
//  PortMap
//
//  Created by Dominik Wagner on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import <TCMPortMapper/TCMPortMapper.h>

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperExternalIPAddressDidChange:) name:TCMPortMapperExternalIPAddressDidChange object:[TCMPortMapper sharedInstance]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperWillSearchForRouter:) name:TCMPortMapperWillSearchForRouterNotification object:[TCMPortMapper sharedInstance]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFindRouter:) name:TCMPortMapperDidFindRouterNotification object:[TCMPortMapper sharedInstance]];
	[[TCMPortMapper sharedInstance] start]; // Just a test
	[[TCMPortMapper sharedInstance] addPortMapping:[TCMPortMapping portMappingWithPrivatePort:6942 desiredPublicPort:6942 userInfo:nil]];
}

- (IBAction)refresh:(id)aSender {
    [[TCMPortMapper sharedInstance] refresh];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)aSender {
    [[O_currentIPTextField window] orderFront:self];
    return NO;
}

- (void)portMapperExternalIPAddressDidChange:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    [O_currentIPTextField setObjectValue:[pm externalIPAddress]];
    [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerIPAddress],[pm routerHardwareAddress]]];
}

- (void)portMapperWillSearchForRouter:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [O_globalProgressIndicator startAnimation:self];
    [O_refreshButton setEnabled:NO];
}

- (void)portMapperDidFindRouter:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [O_globalProgressIndicator stopAnimation:self];
    [O_refreshButton setEnabled:YES];
}


@end
