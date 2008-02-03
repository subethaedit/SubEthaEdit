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
}

- (IBAction)refresh:(id)aSender {
    [[TCMPortMapper sharedInstance] refresh];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)aSender {
    [[O_currentIPTextField window] orderFront:self];
    return NO;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%s %@ %@ %@",__FUNCTION__,keyPath,object,change);
    if ([[[object userInfo] objectForKey:@"active"] boolValue]) {
        [[TCMPortMapper sharedInstance] addPortMapping:object];
    } else {
        [[TCMPortMapper sharedInstance] removePortMapping:object];
    }
}

- (void)portMapperExternalIPAddressDidChange:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm externalIPAddress]) {
        [O_currentIPTextField setObjectValue:[pm externalIPAddress]];
        [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerIPAddress],[pm routerHardwareAddress]]];
    } else {
        [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerIPAddress],[pm routerHardwareAddress]]];
    }
}

- (void)portMapperWillSearchForRouter:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [O_globalProgressIndicator startAnimation:self];
    [O_refreshButton setEnabled:NO];
    [O_currentIPTextField setStringValue:@"Searching..."];
}

- (void)portMapperDidFindRouter:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
    [O_globalProgressIndicator stopAnimation:self];
    [O_refreshButton setEnabled:YES];
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm externalIPAddress]) {
        [O_currentIPTextField setObjectValue:[pm externalIPAddress]];
    } else {
        [O_currentIPTextField setStringValue:@"Router incompatible."];
    }
}

- (IBAction)addMapping:(id)aSender {
    [NSApp beginSheet:O_addSheetPanel modalForWindow:[O_currentIPTextField window] modalDelegate:self didEndSelector:@selector(addMappingSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)removeMapping:(id)aSender {
    NSEnumerator *mappings = [[O_mappingsArrayController selectedObjects] objectEnumerator];
    TCMPortMapping *mapping = nil;
    while ((mapping=[mappings nextObject])) {
        if ([[[mapping userInfo] objectForKey:@"active"] boolValue]) {
            [[TCMPortMapper sharedInstance] removePortMapping:mapping];
        }
        [mapping removeObserver:self forKeyPath:@"userInfo.active"];
    }
    [O_mappingsArrayController removeObjects:[O_mappingsArrayController selectedObjects]];
}

- (IBAction)portTextDidChange:(id)aSender {
    [O_addDesiredField setStringValue:[O_addLocalPortField stringValue]];
}

- (void)addMappingSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (IBAction)addMappingEndSheet:(id)aSender {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"active",[O_addDescriptionField stringValue],@"mappingTitle",nil];
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithPrivatePort:[O_addLocalPortField intValue] desiredPublicPort:[O_addDesiredField intValue] userInfo:userInfo];
    int transportProtocol = 0;
    if ([O_addProtocolTCPButton state] == NSOnState) transportProtocol+=TCP;
    if ([O_addProtocolUDPButton state] == NSOnState) transportProtocol+=UDP;
    [mapping setTransportProtocol:transportProtocol];
    [mapping addObserver:self forKeyPath:@"userInfo.active" options:0 context:nil];
    [O_mappingsArrayController addObject:mapping];
    [[TCMPortMapper sharedInstance] addPortMapping:mapping];
    [NSApp endSheet:O_addSheetPanel];
//    [O_addSheetPanel orderOut:self];
}

- (IBAction)addMappingCancelSheet:(id)aSender {
    [NSApp endSheet:O_addSheetPanel];
//    [O_addSheetPanel orderOut:self];
}

@end
