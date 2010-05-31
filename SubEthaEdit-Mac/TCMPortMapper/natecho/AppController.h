//
//  AppController.h
//  Port Map
//
//  Created by Dominik Wagner on 10.02.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPServer.h"

@interface AppController : NSObject {
    IBOutlet NSTextField *O_portTextField;
    IBOutlet NSButton *O_startStopButton;
    IBOutlet NSImageView *O_serverStatusImageView;
    IBOutlet NSTextField *O_serverStatusTextField;
    IBOutlet NSTextField *O_serverReachabilityTextField;

    IBOutlet NSProgressIndicator *O_publicIndicator;
    IBOutlet NSImageView *O_publicStatusImageView;
    IBOutlet NSTextField *O_publicStatusTextField;
    
    NSMutableArray *I_streamsArray;
    TCPServer *I_server;
}

- (IBAction)startStop:(id)aSender;
- (void)start;
- (void)stop;
@end
