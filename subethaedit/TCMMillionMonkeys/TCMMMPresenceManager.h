//
//  TCMMMPresenceManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMMMPresenceManager : NSObject {
    NSMutableDictionary *I_statusOfUserIDs;
}

+ (TCMMMPresenceManager *)sharedInstance;

- (void)statusConnectToNetService:(NSNetService *)aNetService userID:(NSString *)userID sender:(id)aSender;

@end
