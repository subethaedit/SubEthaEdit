//
//  DocumentController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentController.h"
#import "TCMMMSession.h"
#import "PlainTextDocument.h"

@implementation DocumentController

+ (DocumentController *)sharedInstance {
    return (DocumentController *)[NSDocumentController sharedDocumentController];
}

- (void)addDocumentWithSession:(TCMMMSession *)aSession {
    PlainTextDocument *document=[[PlainTextDocument alloc] initWithSession:aSession];
    [document makeWindowControllers];
    [self addDocument:document];
    [document showWindows];
    [document release];
}

@end
