//  UserChangeOperation.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 03 2004.

#import "UserChangeOperation.h"
#import "TCMMMUser.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation UserChangeOperation

+ (void)initialize {
	if (self == [UserChangeOperation class]) {
	    [TCMMMOperation registerClass:self forOperationType:[self operationID]];
	}
}

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType userID:(NSString *)aUserID newGroup:(NSString *)aGroup {
    UserChangeOperation *result=[UserChangeOperation new];
    [result setType:aType];
    [result setUserID:aUserID];
    [result setTheNewGroup:aGroup];
    return result;
}

+ (UserChangeOperation *)userChangeOperationWithType:(int)aType user:(TCMMMUser *)aUser newGroup:(NSString *)aGroup {
    UserChangeOperation *result=[UserChangeOperation new];
    [result setType:aType];
    [result setUserID:[aUser userID]];
    [result setUser:aUser];
    [result setTheNewGroup:aGroup];
    return result;
}


+ (NSString *)operationID {
    return @"usr";
}

- (id)init {
    self = [super init];
    if (self) {
        [self setTheNewGroup:@""];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    UserChangeOperation *copy = [super copyWithZone:zone];

    [copy setTheNewGroup:[self theNewGroup]];
    [copy setType:[self type]];
    [copy setUser:[self user]];
    
    return copy;
}

- (NSString *)description {
    NSMutableString *string=[NSMutableString stringWithFormat:@"UserChangeOperation %@",[self userID]];
    NSString *type=nil;
    switch ([self type]) {
        case UserChangeTypeJoin:
            type=@"Join"; break;
        case UserChangeTypeLeave:
            type=@"Leave"; break;
        case UserChangeTypeGroupChange:
            type=@"GroupChange"; break;
    }
    [string appendFormat:@" %@ %@",type,[self theNewGroup]];
    return string;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super initWithDictionaryRepresentation:aDictionary];
    if (self) {
        [self setType:[[aDictionary objectForKey:@"typ"] unsignedIntValue]];
        [self setTheNewGroup:[aDictionary objectForKey:@"grp"]];
        id userDict=[aDictionary objectForKey:@"usr"];
        if (userDict) {
            TCMMMUser *user=[TCMMMUser userWithNotification:userDict];
            [self setUser:user];
        }
        //NSLog(@"operation: %@", [self description]);
    }
    return self;
}


- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [[super dictionaryRepresentation] mutableCopy];
    [dict setObject:[NSNumber numberWithUnsignedInt:_type] forKey:@"typ"];
    [dict setObject:_theNewGroup forKey:@"grp"];
    TCMMMUser *user=[self user];
    if (user) {
        [dict setObject:[user notification] forKey:@"usr"];
    }
    return dict;
}

- (BOOL)isEqualTo:(id)anObject {
    return ([super isEqualTo:anObject] && 
            _type == [(UserChangeOperation *)anObject type] &&
            [_theNewGroup isEqualToString:[anObject theNewGroup]] &&
            [[self user] isEqualTo:[anObject user]]);
}

@end
