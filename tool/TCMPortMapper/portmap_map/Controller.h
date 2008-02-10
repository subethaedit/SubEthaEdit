//
//  Controller.h
//  PortMapper
//
//  Created by Martin Pittenauer on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Controller : NSObject {
	IBOutlet NSWindow *o_sheetView;
	IBOutlet NSTextField *o_statusTextField;
	IBOutlet NSTextField *o_internalPort;
	IBOutlet NSTextField *o_externalPort;
	IBOutlet NSArrayController *o_arrayController;
	NSArray *portMappings;
}

- (IBAction) addPortMapping:(id)sender;
- (IBAction) mapNewPort:(id)sender;

- (IBAction) removePortMapping:(id)sender;
- (IBAction) refreshPortMappings:(id)sender;

@end
