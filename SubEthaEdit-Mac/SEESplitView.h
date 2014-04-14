//
//  SEESplitView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 10.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SEESplitView;
@protocol SEESplitViewDelegate
@optional
- (NSColor *)dividerColorForSplitView:(SEESplitView *)aSplitView;
@end

@interface SEESplitView : NSSplitView

@end
