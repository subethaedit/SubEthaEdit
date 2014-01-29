//
//  SEEParticipantViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMUser;

@interface SEEParticipantViewController : NSViewController

@property (nonatomic, readonly, strong) TCMMMUser *user;

- (id)initWithParticipant:(TCMMMUser *)aParticipant;

@end
