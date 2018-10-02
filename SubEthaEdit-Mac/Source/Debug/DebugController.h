//  DebugController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Apr 23 2004.

#ifndef TCM_NO_DEBUG


#import <Foundation/Foundation.h>

@class DebugUserController;
@class DebugBEEPController,DebugPresenceController,DebugSendOperationController,DebugAttributeInspectorController, SEEDebugImageGenerationWindowController;

@interface DebugController : NSObject
{
    DebugPresenceController *I_debugPresenceController;
    DebugUserController *I_debugUserController;
    DebugBEEPController *I_debugBEEPController;
    DebugSendOperationController *I_debugSendOperationController;
    DebugAttributeInspectorController *I_debugAttributeInspectorController;
	SEEDebugImageGenerationWindowController *I_debugImageGenerationWindowController;
}

+ (DebugController *)sharedInstance;

- (void)enableDebugMenu:(BOOL)flag;

- (IBAction)showUsers:(id)aSender;
- (IBAction)showBEEP:(id)sender;
- (IBAction)showSendOperation:(id)sender;
- (IBAction)crash:(id)sender;
- (IBAction)createProxyWindow:(id)aSender;
- (IBAction)showAttributeInspector:(id)sender;
- (IBAction)showDebugImageGenerationWindowController:(id)aSender;
@end


#endif
