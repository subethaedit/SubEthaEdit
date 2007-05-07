//
//  SDDirectoryEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDDirectoryEntry.h"
#import "SDDirectory.h"


@implementation SDDirectoryEntry
- (id)initWithShortName:(NSString *)aShortName directory:(SDDirectory *)aDirectory {
    if ((self=[super init])) {
        _directory = aDirectory;
        _shortName = [aShortName copy];
        _fullName = [NSString new];
        _groups = [NSMutableSet new];
        if (![_shortName isEqualToString:kSDDirectoryGroupEveryoneGroupShortName]) {
            [self addToGroup:[_directory groupForShortName:kSDDirectoryGroupEveryoneGroupShortName]];
        }
    }
    return self;
}

- (id)dictionaryRepresentation {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject:[self shortName] forKey:@"shortName"];
    [result setObject:[[_groups allObjects] valueForKeyPath:@"@unionOfObjects.shortName"] forKey:@"groups"];
    [result setObject:[self fullName] forKey:@"fullName"];
    return result;
}

- (void)updateWithDictionaryRepresentation:(NSDictionary *)aRepresentation {
    NSEnumerator *groupNames = [[aRepresentation objectForKey:@"groups"] objectEnumerator];
    NSString *groupName = nil;
    while ((groupName = [groupNames nextObject])) {
        id group = [_directory groupWithShortName:groupName];
        if (group) {
            [self addToGroup:group];
        }
    }
    
    id value = [aRepresentation objectForKey:@"fullName"];
    if (value) {
        [self setValue:value forKeyPath:@"fullName"];
    }
}

- (void)dealloc {
    [_shortName release];
    [_fullName release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %d> shortName:%@, groups:%@",NSStringFromClass([self class]),(int)self,[self valueForKey:@"shortName"],[[_groups allObjects] valueForKeyPath:@"@unionOfObjects.shortName"]];
}

- (NSString *)shortName {
    return _shortName;
}

- (NSString *)fullName {
    return _fullName;
}

- (void)setFullName:(NSString *)aString {
    [_fullName autorelease];
    _fullName = [aString copy];
}

- (void)addToGroup:(SDDirectoryGroup *)aGroup {
    [_groups addObject:aGroup];
}
- (void)removeFromGroup:(SDDirectoryGroup *)aGroup {
    [_groups removeObject:aGroup];
}

- (BOOL)isMemberOfGroup:(SDDirectoryGroup *)aGroup {
    if ([_groups containsObject:aGroup]) {
        return YES;
    } else {
        NSEnumerator *groups = [_groups objectEnumerator];
        SDDirectoryEntry *group = nil;
        while ((group=[groups nextObject])) {
            if ([group isMemberOfGroup:aGroup]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
