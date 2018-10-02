//  SEEEditorSplitViewDelegate.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.03.14.

#import <Cocoa/Cocoa.h>

#define SPLITMINHEIGHTTEXT   46.0

@class PlainTextWindowControllerTabContext;

@interface SEEEditorSplitViewDelegate : NSObject <NSSplitViewDelegate>
- (instancetype)initWithTabContext:(PlainTextWindowControllerTabContext *)tabContext;
@end
