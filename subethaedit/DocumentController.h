//
//  DocumentController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TCMMMSession;

@interface DocumentController : NSDocumentController {

}

+(DocumentController *)sharedInstance;

- (void)addDocumentWithSession:(TCMMMSession *)aSession;

@end
