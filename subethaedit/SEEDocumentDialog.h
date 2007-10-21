//
//  SEEDocumentDialog.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SEEDocumentDialog : NSObject {
    IBOutlet NSWindow *O_window;
    NSView *O_mainView;
    NSSize I_maxSize;
    NSSize I_minSize;
    NSArray *I_topLevelNibObjects;
    id I_document;
}

/*"Setting up the main view"*/
- (NSView *)assignMainView;
- (NSView *)loadMainView;
- (NSString *)mainNibName;
- (NSView *)mainView;
- (void)mainViewDidLoad;
- (void)setMainView:(NSView *)aView;

- (id)document;
- (void)setDocument:(id)aDocument;
- (IBAction)orderOut:(id)aSender;

@end
