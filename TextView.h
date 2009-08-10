//
//  TextView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PlainTextEditor; 

@interface TextView : NSTextView {
    BOOL I_isDragTarget;
    struct {
        BOOL shouldCheckCompleteStart;
        BOOL autoCompleteInProgress;
        BOOL isPasting;
        BOOL isDraggingText;
        BOOL isDoingUglyHack;
    } I_flags;
    float I_pageGuidePosition;
    NSTimer *I_timer;
	PlainTextEditor* editor;
}

- (void)setEditor:(PlainTextEditor*)inEditor;
- (PlainTextEditor*)editor;
+ (void)setDefaultMenu:(NSMenu *)aMenu;
- (void)setPageGuidePosition:(float)aPosition;
- (BOOL)isPasting;

- (IBAction)foldTextSelection:(id)aSender;

#pragma mark Folding Related Methods
- (void)scrollFullRangeToVisible:(NSRange)aRange;
- (IBAction)foldCurrentBlock:(id)aSender;
- (IBAction)foldTextSelection:(id)aSender;
- (IBAction)unfoldCurrentBlock:(id)aSender;
- (IBAction)foldAllCommentBlocks:(id)aSender;
- (IBAction)foldAllTopLevelBlocks:(id)aSender;
- (IBAction)foldAllBlocksAtTagLevel:(id)aSender;

@end

@interface NSObject (TextViewDelegateMethods) 
- (void)textView:(NSTextView *)aTextView mouseDidGoDown:(NSEvent *)aEvent;
- (NSDictionary *)blockeditAttributesForTextView:(NSTextView *)aTextView;
- (void)textViewDidChangeSpellCheckingSetting:(TextView *)aTextView;
- (void)textView:(TextView *)aTextView didFinishAutocompleteByInsertingCompletion:(NSString *)aWord forPartialWordRange:(NSRange)aCharRange movement:(int)aMovement;
- (void)textViewWillStartAutocomplete:(TextView *)aTextView;
- (void)textViewContextMenuNeedsUpdate:(NSMenu *)aContextMenu;
@end
