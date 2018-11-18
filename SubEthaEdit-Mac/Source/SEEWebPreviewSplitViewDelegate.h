//  SEEWebPreviewSplitViewDelegate.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.03.14.

#import <Cocoa/Cocoa.h>

@class PlainTextWindowControllerTabContext;

@interface SEEWebPreviewSplitViewDelegate : NSObject <NSSplitViewDelegate>
- (instancetype)initWithTabContext:(PlainTextWindowControllerTabContext *)tabContext;
@end
