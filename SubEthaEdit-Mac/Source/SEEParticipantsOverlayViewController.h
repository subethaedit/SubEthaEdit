//  SEEParticipantsOverlayViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.01.14.

#import <Cocoa/Cocoa.h>

@class PlainTextWindowControllerTabContext;

@interface SEEParticipantsOverlayViewController : NSViewController
- (instancetype)initWithTabContext:(PlainTextWindowControllerTabContext *)aTabContext;
- (void)updateColorsForIsDarkBackground:(BOOL)isDark;
@end
