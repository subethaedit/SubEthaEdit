//
//  TCMMMUser.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBencodingUtilities.h"
#import "TCMMMUser.h"


@implementation TCMMMUser

- (id)init {
    if ((self=[super init])) {
        I_properties=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_properties release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TCMMMUser <ID:%@,properties:%@>",[self ID],[self properties]];
}

- (void)setID:(NSString *)aID {
    [I_ID autorelease];
     I_ID=[aID copy];
}
- (NSString *)ID {
    return I_ID;
}

- (void)setServiceName:(NSString *)aServiceName {
    [I_serviceName autorelease];
     I_serviceName=[aServiceName copy];
}
- (NSString *)serviceName {
    return I_serviceName;
}
- (void)setName:(NSString *)aName {
    [I_name autorelease];
     I_name=[aName copy];
}
- (NSString *)name {
    return I_name;
}

- (NSData *)userBencoded {
    NSDictionary *user=[NSDictionary dictionaryWithObjectsAndKeys:[self name],@"Name",[self ID],@"ID",nil];
    return TCM_BencodedObject(user);
}

- (NSMutableDictionary *)properties {
    return I_properties;
}

@end
