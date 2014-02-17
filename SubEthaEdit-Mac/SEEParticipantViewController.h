//
//  SEEParticipantViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PlainTextDocument, TCMMMUser;

@interface SEEParticipantViewController : NSViewController

@property (nonatomic, readonly, strong) TCMMMUser *participant;
@property (nonatomic, assign) BOOL isParticipantFollowed;

- (id)initWithParticipant:(TCMMMUser *)aParticipant inDocument:(PlainTextDocument *)document;

- (void)updateForParticipantUserState;
- (void)updateForPendingUserState;
- (void)updateForInvitationState;

@end
