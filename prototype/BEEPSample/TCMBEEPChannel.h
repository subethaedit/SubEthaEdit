//
//  TCMBEEPChannel.h
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMBEEPSession;

@interface TCMBEEPChannel : NSObject
{
    unsigned long I_number;
    TCMBEEPSession *I_session;
    NSString *I_profileURI;
    id I_profile;
}

+ (NSDictionary *)profileURIToClassMapping;
+ (void)setClass:(Class)aClass forProfileURI:(NSString *)aProfileURI;

- (id)initWithSession:(TCMBEEPSession *)aSession number:(unsigned long)aNumber profileURI:(NSString *)aProfileURI;

- (void)setNumber:(unsigned long)aNumber;
- (unsigned long)number;

- (void)setSession:(TCMBEEPSession *)aSession;
- (TCMBEEPSession *)session;

- (void)setProfileURI:(NSString *)aProfileURI;
- (NSString *)profileURI;

- (id)profile;

@end
