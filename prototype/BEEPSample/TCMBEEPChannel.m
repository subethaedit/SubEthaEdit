//
//  TCMBEEPChannel.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPChannel.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPManagementProfile.h"

static NSMutableDictionary *profileURIToClassMapping;

@implementation TCMBEEPChannel

/*"Initializes the class before it’s used. See NSObject."*/

+ (void)initialize {
    profileURIToClassMapping=[NSMutableDictionary new];
    [self setClass:[TCMBEEPManagementProfile class] forProfileURI:kTCMBEEPManagementProfile];
}

/*""*/
+ (NSDictionary *)profileURIToClassMapping {
    return profileURIToClassMapping;
}

/*""*/
+ (void)setClass:(Class)aClass forProfileURI:(NSString *)aProfileURI {
    [profileURIToClassMapping setObject:aClass forKey:aProfileURI];
}

/*""*/
- (id)initWithSession:(TCMBEEPSession *)aSession number:(unsigned long)aNumber profileURI:(NSString *)aProfileURI
{
    self = [super init];
    if (self) {
        Class profileClass=nil;
        if (profileClass=[[TCMBEEPChannel profileURIToClassMapping] objectForKey:aProfileURI]) {
            I_profile=[profileClass new];
            [self setSession:aSession];
            [self setNumber:aNumber];
            [self setProfileURI:aProfileURI];
        }
    }
    
    return self;
}

/*""*/
- (void)setNumber:(unsigned long)aNumber
{
    I_number = aNumber;
}

/*""*/
- (unsigned long)number
{
    return I_number;
}

/*""*/
- (void)setSession:(TCMBEEPSession *)aSession
{
    I_session = aSession;
}

/*""*/
- (TCMBEEPSession *)session
{
    return I_session;
}

/*""*/
- (void)setProfileURI:(NSString *)aProfileURI
{
    [I_profileURI autorelease];
    I_profileURI = [aProfileURI copy];
}

/*""*/
- (NSString *)profileURI
{
    return I_profileURI;
}

/*""*/
- (id)profile {
    return I_profile;
}

@end

