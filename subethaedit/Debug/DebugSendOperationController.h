//
//  DebugSendOperationController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 16.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#ifndef TCM_NO_DEBUG


#import <Cocoa/Cocoa.h>


@interface DebugSendOperationController : NSWindowController {
    int _operationLocation;
    int _operationLength;
    NSString *_operationReplacementString;
}

- (IBAction)sendTextOperation:(id)aSender;
- (IBAction)sendSelectionOperation:(id)aSender;

@end


#endif