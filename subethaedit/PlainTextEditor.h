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
    IBOutlet NSTextField *O_writtenByTextField;
    IBOutlet NSTextField *O_modeTextField;
    IBOutlet NSTextField *O_encodingTextField;
    IBOutlet NSPopUpButton *O_symbolPopUpButton;
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
        BOOL hasSplitButton;
    } I_flags;
}


- (id)initWithWindowController:(NSWindowController *)aWindowController splitButton:(BOOL)aFlag;
- (NSView *)editorView;
- (NSTextView *)textView;
- (PlainTextDocument *)document;
- (void)setIsSplit:(BOOL)aFlag;

- (void)setShowsChangeMarks:(BOOL)aFlag;
- (BOOL)showsChangeMarks;
- (void)setWrapsLines:(BOOL)aFlag;
- (BOOL)wrapsLines;
- (void)setShowsInvisibleCharacters:(BOOL)aFlag;
- (BOOL)showsInvisibleCharacters;
- (BOOL)showsGutter;
- (void)setShowsGutter:(BOOL)aFlag;
- (BOOL)showsTopStatusBar;
- (void)setShowsTopStatusBar:(BOOL)aFlag;
- (BOOL)showsBottomStatusBar;
- (void)setShowsBottomStatusBar:(BOOL)aFlag;

- (void)takeSettingsFromDocument;

#pragma mark -
#pragma mark ### Actions ###
- (IBAction)toggleWrap:(id)aSender;
- (IBAction)toggleLineNumbers:(id)aSender;
- (IBAction)toggleShowsChangeMarks:(id)aSender;
- (IBAction)chooseSymbol:(id)aSender;
@end
