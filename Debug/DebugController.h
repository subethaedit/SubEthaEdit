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
@class DebugBEEPController,DebugPresenceController,DebugSendOperationController,DebugAttributeInspectorController;

@interface DebugController : NSObject
{
    DebugPresenceController *I_debugPresenceController;
    DebugUserController *I_debugUserController;
    DebugBEEPController *I_debugBEEPController;
    DebugSendOperationController *I_debugSendOperationController;
    DebugAttributeInspectorController *I_debugAttributeInspectorController;
}

+ (DebugController *)sharedInstance;

- (void)enableDebugMenu:(BOOL)flag;

- (IBAction)showUsers:(id)aSender;
- (IBAction)showBEEP:(id)sender;
- (IBAction)showSendOperation:(id)sender;
- (IBAction)crash:(id)sender;
- (IBAction)createProxyWindow:(id)aSender;
- (IBAction)showAttributeInspector:(id)sender;
@end


#endif