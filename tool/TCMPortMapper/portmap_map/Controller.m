//
//  Controller.m
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "Controller.h"
#import "TCMPortMapper.h"


@implementation Controller

- (void) awakeFromNib {
	//[o_statusTextField setStringValue:[NSString stringWithFormat:@"Status: External IP is %@", [[TCMPortMapper sharedInstance] externalIPAddress]]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperNotifications:) name:nil object:[TCMPortMapper sharedInstance]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperNotifications:) name:TCMPortMappingDidChangeMappingStatusNotification object:nil];
	[[TCMPortMapper sharedInstance] start]; // Just a test
	[[TCMPortMapper sharedInstance] addPortMapping:[TCMPortMapping portMappingWithPrivatePort:6942 desiredPublicPort:6942 userInfo:nil]];
}

- (IBAction) addPortMapping:(id)sender {
	[NSApp beginSheet:o_sheetView modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:returnCode:contextInfo:) contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	
}

- (void)portMapperNotifications:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
}

@end
