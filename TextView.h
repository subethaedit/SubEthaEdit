//
//  TextView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

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
}

+ (void)setDefaultMenu:(NSMenu *)aMenu;
- (void)setPageGuidePosition:(float)aPosition;
- (BOOL)isPasting;

@end

@interface NSObject (TextViewDelegateMethods) 
- (void)textView:(NSTextView *)aTextView mouseDidGoDown:(NSEvent *)aEvent;
- (NSDictionary *)blockeditAttributesForTextView:(NSTextView *)aTextView;
- (void)textViewDidChangeSpellCheckingSetting:(TextView *)aTextView;
- (void)textView:(TextView *)aTextView didFinishAutocompleteByInsertingCompletion:(NSString *)aWord forPartialWordRange:(NSRange)aCharRange movement:(int)aMovement;
- (void)textViewWillStartAutocomplete:(TextView *)aTextView;
- (void)textViewContextMenuNeedsUpdate:(NSMenu *)aContextMenu;
@end
