//
//  MyDocument.h
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Fri Jan 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "SyntaxHighlighter.h"
#import "SyntaxManager.h"
#import "LineNumberRulerView.h"
#import "TextStorage.h"
#import "TextPopUpControl.h"

@interface MyDocument : NSDocument
{
    IBOutlet NSWindow     *O_window;
    IBOutlet NSScrollView *O_scrollView;
    IBOutlet NSTextField  *O_positionTextField;
    IBOutlet TextPopUpControl *O_symbolPopUpButton;
    
    NSTextView *I_textView;
    TextStorage *I_textStorage;
    NSTextContainer *I_textContainer;
    NSMutableDictionary *I_textAttributes; /*"Base text Attributes used by the Highlighter to reset attributation"*/
    NSString *I_syntaxName;
    SyntaxHighlighter *I_syntaxHighlighter;
    struct {
        BOOL colorizeSyntax; /*"Syntax Highlighting on?"*/
        BOOL performingSyntaxColorize; /*"Syntax Highlighting NSTimer Loop on?"*/
        BOOL symbolListNeedsUpdate; /*""*/
        BOOL symbolPopUpMenuNeedsUpdate;
        BOOL symbolLastPopUpMenuWasSorted;
    } I_flags;
    NSArray *I_symbols;
    NSMenu *I_symbolPopUpMenu;
    NSMenu *I_symbolPopUpMenuSorted;
    NSTimer *I_selectedSymbolUpdateTimer;
    
    double lasttime;
}


/*"Accessors"*/
- (void)setSyntaxName:(NSString *)aSyntaxName;


/*"Syntax Coloring"*/
- (void)syntaxColorizeInRange:(NSRange)aRange;
- (void)syntaxColorize;
- (void)performSyntaxColorize:(id)aSender;
- (IBAction)toggleSyntaxColoring:(id)aSender;
- (IBAction)chooseSyntaxName:(id)aSender;

/*"Syntax Coloring Testing"*/
- (IBAction)runTest:(id)aSender;

/*"Text View Delegation"*/
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)aAffectedCharRange 
                                               replacementString:(NSString *)aReplacementString;
- (void)textDidChange:(NSNotification *)aNotification;
@end
