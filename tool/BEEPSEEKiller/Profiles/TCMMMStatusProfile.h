//
//  TCMMMStatusProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TCMBEEP/TCMBEEP.h>

@class TCMMMUser, TCMMMSession;

@interface TCMMMStatusProfile : TCMBEEPProfile {

}

- (void)requestUser;
- (void)sendUserDidChangeNotification;
- (void)sendVisibility:(BOOL)isVisible;
@end
