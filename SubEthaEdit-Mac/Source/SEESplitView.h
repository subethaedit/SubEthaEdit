//  SEESplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.14.

#import <Cocoa/Cocoa.h>
@class SEESplitView;
@protocol SEESplitViewDelegate
@optional
- (void)splitViewEffectiveAppearanceDidChange:(SEESplitView *)aSplitView;
- (NSColor *)dividerColorForSplitView:(SEESplitView *)aSplitView;
@end

@interface SEESplitView : NSSplitView

@end
