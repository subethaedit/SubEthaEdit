//
//  SEEParticipantViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextWindowControllerTabContext, TCMMMUser;

@interface SEEParticipantViewController : NSViewController

@property (nonatomic, readonly, strong) TCMMMUser *participant;
@property (nonatomic, assign) BOOL isParticipantFollowed;

- (id)initWithParticipant:(TCMMMUser *)aParticipant tabContext:(PlainTextWindowControllerTabContext *)aTabContext;

- (void)updateColorsForIsDarkBackground:(BOOL)isDark;

- (void)updateForParticipantUserState;
- (void)updateForPendingUserState;
- (void)updateForInvitationState;

@end
