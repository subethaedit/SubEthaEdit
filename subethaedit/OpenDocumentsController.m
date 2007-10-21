//
//  OpenDocumentsController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "OpenDocumentsController.h"
#import "DocumentController.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"

@implementation OpenDocumentsController

- (id)init {
    if ((self=[super initWithWindowNibName:@"OpenDocuments"])) {
    }
    return self;
}

- (void)windowDidLoad {
    [O_objectController setContent:[DocumentController sharedInstance]];
    [O_documentsTableView setDoubleAction:@selector(showSelected:)];
}

- (IBAction)showSelected:(id)aSender {
    NSEnumerator *documents=[[O_arrayController selectedObjects] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document = [documents nextObject])) {
        [[document topmostWindowController] showWindow:aSender];
    }
}

- (IBAction)closeSelected:(id)aSender {
    NSEnumerator *documents=[[O_arrayController selectedObjects] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document = [documents nextObject])) {
        NSEnumerator *windowControllers=[[document windowControllers] objectEnumerator];
        NSWindowController *controller=nil;
        while ((controller=[windowControllers nextObject])) {
            [[controller window] performClose:aSender];
        }
    }
}
- (IBAction)saveSelected:(id)aSender {
    NSEnumerator *documents=[[O_arrayController selectedObjects] objectEnumerator];
    PlainTextDocument *document=nil;
    while ((document = [documents nextObject])) {
        [document saveDocument:aSender];
    }
}


@end
