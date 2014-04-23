//
//  SEEParticipantViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextWindowControllerTabContext, TCMMMUser;

typedef NS_ENUM(NSInteger, SEEParticipantViewMode) {
	SEEParticipantViewModeUnknown = -1,
	SEEParticipantViewModeParticipant = 0,
	SEEParticipantViewModeInvited,
	SEEParticipantViewModePending
};

@interface SEEParticipantViewController : NSViewController

@property (nonatomic, readonly, assign) SEEParticipantViewMode viewMode;
@property (nonatomic, readonly, strong) TCMMMUser *participant;
@property (nonatomic, assign) BOOL isParticipantFollowed;

@property (nonatomic, readonly, strong) NSColor *popoverTextColor;

- (id)initWithParticipant:(TCMMMUser *)aParticipant tabContext:(PlainTextWindowControllerTabContext *)aTabContext inMode:(SEEParticipantViewMode)aMode;

- (void)updateColorsForIsDarkBackground:(BOOL)isDark;

@end
