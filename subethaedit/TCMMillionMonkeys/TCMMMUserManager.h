//
//  TCMMMUserManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMMMUserManager : NSObject {
    NSMutableDictionary *I_usersByID;
}

+(TCMMMUserManager *)sharedInstance;

@end
