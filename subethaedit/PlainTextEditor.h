//
//  PlainTextEditorWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PlainTextDocument;

@interface PlainTextEditor : NSResponder {
    IBOutlet NSTextField *O_positionTextField;
    IBOutlet NSTextField *O_tabStatusTextField;
    IBOutlet NSTextField *O_windowWidthTextField;
    IBOutlet NSTextField *O_modeTextField;
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet NSView       *O_editorView;
    IBOutlet NSView       *O_topStatusBarView;
    IBOutlet NSView       *O_bottomStatusBarView;
    NSTextView      *I_textView;
    NSTextContainer *I_textContainer;
    NSWindowController *I_windowController;
    struct {
        BOOL showTopStatusBar;
        BOOL showBottomStatusBar;
    } I_flags;
}


- (id)initWithWindowController:(NSWindowController *)aWindowController;
- (NSView *)editorView;
- (NSTextView *)textView;
- (PlainTextDocument *)document;

- (BOOL)showsTopStatusBar;
- (void)setShowsTopStatusBar:(BOOL)aFlag;
- (BOOL)showsBottomStatusBar;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;

@end
