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

@interface DebugController : NSObject
{
    DebugUserController *I_debugUserController;
}

+ (DebugController *)sharedInstance;

- (void)enableDebugMenu:(BOOL)flag;

- (IBAction)showUsers:(id)aSender;

@end


#endif