//
//  SEEPlainTextParticipantViewController.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMUser;

@interface SEEPlainTextParticipantViewController : NSViewController
@property (nonatomic, readonly, strong) TCMMMUser *user;
@property (nonatomic, strong) IBOutlet NSView *participantView;
@end
