//
//  SEEEditorSplitViewDelegate.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SPLITMINHEIGHTTEXT   46.0

@class PlainTextWindowControllerTabContext;

@interface SEEEditorSplitViewDelegate : NSObject <NSSplitViewDelegate>
- (instancetype)initWithTabContext:(PlainTextWindowControllerTabContext *)tabContext;
@end
