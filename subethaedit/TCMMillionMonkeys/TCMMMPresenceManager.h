//
//  TCMMMPresenceManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMMMPresenceManager : NSObject {
    NSNetService *I_netService;
    NSMutableDictionary *I_statusOfUserIDs;
    struct {
        BOOL isVisible;
        BOOL serviceIsPublished;
    } I_flags;
}

+ (TCMMMPresenceManager *)sharedInstance;

- (void)statusConnectToNetService:(NSNetService *)aNetService userID:(NSString *)userID sender:(id)aSender;

- (void)setVisible:(BOOL)aFlag;

@end
