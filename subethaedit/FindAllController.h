//
//  FindAllController.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "PlainTextDocument.h"

@interface FindAllController : NSObject {
    IBOutlet NSPanel *O_findAllPanel;
    IBOutlet NSArrayController *O_resultsController;
    IBOutlet NSTextField *O_findResultsTextField;
    PlainTextDocument *I_document;
    OGRegularExpression *I_regularExpression;
    unsigned I_options;
}

- (id)initWithRegex:(OGRegularExpression*)regex andOptions:(unsigned)options;
- (void) findAll;
- (void)setDocument:(PlainTextDocument *)aDocument;
- (NSPanel *)findAllPanel;

@end
