//
//  FindAllController.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Wed May 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
@class FindAllController;
#import "PlainTextDocument.h"
#import "SelectionOperation.h"
#import "SEEFindAndReplaceContext.h"

@interface FindAllController : NSWindowController <NSWindowDelegate,NSTableViewDelegate> {
    IBOutlet NSPanel *O_findAllPanel;
    IBOutlet NSArrayController *O_resultsController;
    IBOutlet NSTextField *O_findResultsTextField;
    IBOutlet NSTextField *O_findRegexTextField;
    IBOutlet NSTableView *O_resultsTableView;
    IBOutlet NSProgressIndicator *O_progressIndicator;
    PlainTextDocument *I_document;
}

@property (nonatomic, strong) SEEFindAndReplaceContext *findAndReplaceContext;

- (instancetype)initWithFindAndReplaceContext:(SEEFindAndReplaceContext *)aFindAndReplaceContext;
- (IBAction)findAll:(id)sender;
- (void)setDocument:(PlainTextDocument *)aDocument;
- (NSArray*)arrangedObjects;

@end
