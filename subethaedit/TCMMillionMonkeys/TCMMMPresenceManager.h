//
//  TCMMMPresenceManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMMMStatusProfile, TCMHost, TCMMMSession;

@interface TCMMMPresenceManager : NSObject
{
    NSNetService *I_netService;
    NSMutableDictionary *I_statusOfUserIDs;
    NSMutableSet        *I_statusProfilesInServerRole;
    NSMutableDictionary *I_announcedSessions;
    struct {
        BOOL isVisible;
        BOOL serviceIsPublished;
    } I_flags;
}

+ (TCMMMPresenceManager *)sharedInstance;

- (void)setVisible:(BOOL)aFlag;

- (void)acceptStatusProfile:(TCMMMStatusProfile *)aProfile;

- (void)announceSession:(TCMMMSession *)aSession;
- (void)concealSession:(TCMMMSession *)aSession;


@end
