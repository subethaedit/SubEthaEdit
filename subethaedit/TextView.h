//
//  TextView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface TextView : NSTextView {
    BOOL I_isDragTarget;
}
+ (void)setDefaultMenu:(NSMenu *)aMenu;
@end

@interface NSObject (TextViewDelegateMethods) 
- (void)textView:(NSTextView *)aTextView mouseDidGoDown:(NSEvent *)aEvent;
- (NSDictionary *)blockeditAttributesForTextView:(NSTextView *)aTextView;
@end