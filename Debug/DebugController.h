//
//  DebugController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import <Foundation/Foundation.h>

@class DebugUserController;
@class DebugBEEPController,DebugPresenceController;

@interface DebugController : NSObject
{
    DebugPresenceController *I_debugPresenceController;
    DebugUserController *I_debugUserController;
    DebugBEEPController *I_debugBEEPController;
}

+ (DebugController *)sharedInstance;

- (void)enableDebugMenu:(BOOL)flag;

- (IBAction)showUsers:(id)aSender;
- (IBAction)showBEEP:(id)sender;
- (IBAction)crash:(id)sender;
- (IBAction)createProxyWindow:(id)aSender;

@end


#endif