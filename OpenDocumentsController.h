//
//  OpenDocumentsController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface OpenDocumentsController : NSWindowController {
    IBOutlet NSObjectController *O_objectController;
    IBOutlet NSArrayController  *O_arrayController;
    IBOutlet NSTableView        *O_documentsTableView;
}

- (IBAction)showSelected:(id)aSender;
- (IBAction)closeSelected:(id)aSender;
- (IBAction)saveSelected:(id)aSender;

@end
