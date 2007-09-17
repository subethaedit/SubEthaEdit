//
//  DocumentSharedMethods.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 17.09.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef TCM_ISSEED
#import "PlainTextDocument.h"
@class PlainTextDocument;
@interface PlainTextDocument (DocumentSharedMethods) 
#else
#import "SDDocument.h"
@class SDDocument;
@interface SDDocument (DocumentSharedMethods) 
#endif

@end
