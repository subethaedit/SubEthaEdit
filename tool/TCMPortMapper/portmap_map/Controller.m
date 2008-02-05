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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperNotifications:) name:nil object:[TCMPortMapper sharedInstance]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperNotifications:) name:TCMPortMappingDidChangeMappingStatusNotification object:nil];
	[[TCMPortMapper sharedInstance] start]; 

}

- (IBAction) addPortMapping:(id)sender {
	[NSApp beginSheet:o_sheetView modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)mapNewPort:(id)sender {

	int internal = [o_internalPort intValue];
	int external = [o_externalPort intValue];
	
	NSLog(@"%s:%d %d->%d",__PRETTY_FUNCTION__,__LINE__, internal, external);

	TCMPortMapping *newPortMapping = [TCMPortMapping portMappingWithPrivatePort:internal desiredPublicPort:external userInfo:nil];
	[o_arrayController addObject:newPortMapping];
	
	[[TCMPortMapper sharedInstance] addPortMapping:newPortMapping];
	
	[o_sheetView orderOut:nil];
	[NSApp endSheet:o_sheetView];
}

- (void)portMapperNotifications:(NSNotification *)aNotification {
    NSLog(@"%s %@",__FUNCTION__,aNotification);
}

@end
