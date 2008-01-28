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
	
	[[TCMPortMapper sharedInstance] start]; // Just a test
}

- (IBAction) addPortMapping:(id)sender {
	[NSApp beginSheet:o_sheetView modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:returnCode:contextInfo:) contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	
}

@end
