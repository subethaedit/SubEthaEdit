//
//  TCMMMStatusProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../TCMBEEP/TCMBEEP.h"

@class TCMMMUser;

@interface TCMMMStatusProfile : TCMBEEPProfile {

}

- (void)sendMyself:(TCMMMUser *)aUser;
@end

@interface NSObject (TCMMMStatusProfileDelegateMethods) 
- (void)sendVisibility:(BOOL)isVisible;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveUser:(TCMMMUser *)aUser;
- (void)profile:(TCMMMStatusProfile *)aProfile didReceiveVisibilityChange:(BOOL)isVisible;
@end
