//
//  SEEParticipantsOverlayViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextWindowControllerTabContext;

@interface SEEParticipantsOverlayViewController : NSViewController
- (id)initWithTabContext:(PlainTextWindowControllerTabContext *)aTabContext;
- (void)updateColorsForIsDarkBackground:(BOOL)isDark;
@end
