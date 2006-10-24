//
//  ODBEditorController.h
//  flyopts
//
//  Created by August Mueller on 11/18/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FOODBEditorController : NSObject {
    NSMutableSet *editingTextViews;
    
    IBOutlet NSWindow *latestEditInProgressSheet;
}

+ (id) sharedController;

- (IBAction) endEditSession:(id)sender;

- (NSMutableSet *)editingTextViews;
- (void)setEditingTextViews:(NSMutableSet *)newEditingTextViews;

- (void) openInODBEditor:(NSTextView*)textView;

@end
