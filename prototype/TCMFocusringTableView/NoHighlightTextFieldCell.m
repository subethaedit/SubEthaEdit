//
//  NoHighlightTextFieldCell.m
//  TCMFocusringTableView
//
//  Created by Dominik Wagner on 12.10.04.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NoHighlightTextFieldCell.h"


@implementation NoHighlightTextFieldCell

- (void)setHighlighted:(BOOL)flag {
    //NSLog(@"setHighlighted:%@",flag?@"YES":@"NO");
    [super setHighlighted:NO];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    //NSLog(@"Do nothing");
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
     //NSLog(@"highlightColorWithFrame");
     //return [NSColor whiteColor];
     return nil;
     //return [super highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView];
 }

//-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//    NSLog(@"Do less");
//}
//
//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//    NSLog(@"Forget Frames");
//}

@end
