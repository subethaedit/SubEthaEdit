//
//  PlainTextEditorWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface PlainTextEditor : NSResponder {
    IBOutlet NSTextField *O_positionTextField;
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet NSView       *O_editorView;
    NSTextView      *I_textView;
    NSTextContainer *I_textContainer;
    NSWindowController *I_windowController;
}

- (id)initWithWindowController:(NSWindowController *)aWindowController;
- (NSView *)editorView;
- (NSTextView *)textView;

@end
