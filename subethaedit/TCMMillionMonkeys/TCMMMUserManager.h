//
//  TCMMMUserManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMMMUser;

@interface TCMMMUserManager : NSObject {
    NSMutableDictionary *I_usersByID;
    TCMMMUser *I_me;
}

+ (TCMMMUserManager *)sharedInstance;

- (void)setMe:(TCMMMUser *)aUser;
- (TCMMMUser *)me;
- (TCMMMUser *)userForID:(NSString *)aID;
- (void)setUser:(TCMMMUser *)aUser forID:(NSString *)aID;
@end
