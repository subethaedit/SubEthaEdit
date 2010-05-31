//
//  SDDirectoryUser.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDDirectoryUser.h"
#import "SDDirectory.h"

@implementation SDDirectoryUser

- (id)initWithShortName:(NSString *)aShortName directory:(SDDirectory *)aDirectory {
    if ((self=[super initWithShortName:aShortName directory:aDirectory])) {
        _role = kSDDirectoryGuestRole;
    }
    return self;
}

- (id)dictionaryRepresentation {
    NSMutableDictionary *result = [super dictionaryRepresentation];
    if (_password) {
        [result setObject:_password forKey:@"password"];
    }
    [result setObject:_role forKey:@"role"];
    return result;
}


- (void)updateWithDictionaryRepresentation:(NSDictionary *)aRepresentation {
    [super updateWithDictionaryRepresentation:aRepresentation];

    id value = [aRepresentation objectForKey:@"password"];
    if (value) {
        [self setValue:value forKeyPath:@"password"];
    }

    value = [aRepresentation objectForKey:@"role"];
    if (value) {
        [self setValue:value forKeyPath:@"role"];
    }
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %d> shortName:%@, role:%@, password:%@, groups:%@",NSStringFromClass([self class]),(int)self,[self valueForKey:@"shortName"],[self valueForKey:@"role"],[self valueForKey:@"password"],[[_groups allObjects] valueForKeyPath:@"@unionOfObjects.shortName"]];
}


- (void)dealloc {
    [_role release];
    [_password release];
    [super dealloc];
}

- (NSString *)role {
    return _role;
}
- (NSString *)password {
    return _password;
}


@end
