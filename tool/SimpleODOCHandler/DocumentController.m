//
//  DocumentController.m
//  SimpleODOCHandler
//
//  Created by Martin Ott on Sat Oct 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "DocumentController.h"


@implementation DocumentController

- (id)openDocumentWithContentsOfFile:(NSString *)fileName display:(BOOL)flag
{
    id document = [super openDocumentWithContentsOfFile:fileName display:flag];
    NSLog(@"openDocumentWithContentsOfFile:display:");
    
    NSAppleEventDescriptor *descriptor = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];
    
    NSLog(@"currentAppleEvent: %@", [descriptor description]);
    
    return document;
}

@end
