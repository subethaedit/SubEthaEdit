//
//  SDDirectory.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDDirectory.h"

static SDDirectory *S_sharedInstance = nil;

NSString * const kSDDirectoryGroupEveryoneGroupShortName = @"__everyone__";


@implementation SDDirectory

+ (id)sharedInstance {
    if (!S_sharedInstance) S_sharedInstance = [[SDDirectory alloc] init];
    return S_sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        _usersByShortName  = [NSMutableDictionary new];
        _groupsByShortName = [NSMutableDictionary new];
        [self makeGroupWithShortName:kSDDirectoryGroupEveryoneGroupShortName];
     }
    return self;
}

- (id)smallDictionaryRepresentation {
    return [self dictionaryRepresentation];
}

- (void)dealloc {
    [_usersByShortName  release];
    [_groupsByShortName release];
    
    [super dealloc];
}

- (id)entryForShortName:(NSString *)aShortName {
    id result = [_usersByShortName objectForKey:aShortName];
    if (!result) result = [_groupsByShortName objectForKey:aShortName];
    return result;
}
- (id)userForShortName:(NSString *)aShortName {
    id result = [_usersByShortName objectForKey:aShortName];
    return result;
}
- (id)groupForShortName:(NSString *)aShortName {
    id result = [_groupsByShortName objectForKey:aShortName];
    return result;
}

- (id)makeUserWithShortName:(NSString *)aShortName {
    id entry = [self entryForShortName:aShortName];
    if (entry) {
        NSLog(@"--> %s an entry with shortname <%@> already existed: %@",__FUNCTION__,aShortName,entry);
        return nil;
    }
    id result = [[[SDDirectoryUser alloc] initWithShortName:aShortName directory:self] autorelease];
    [_usersByShortName setObject:result forKey:aShortName];
    return result;
}

- (id)makeGroupWithShortName:(NSString *)aShortName {
    id entry = [self entryForShortName:aShortName];
    if (entry) {
        NSLog(@"--> %s an entry with shortname <%@> already existed: %@",__FUNCTION__,aShortName,entry);
        return nil;
    }
    id result = [[[SDDirectoryGroup alloc] initWithShortName:aShortName directory:self] autorelease];
    [_groupsByShortName setObject:result forKey:aShortName];
    return result;
}

- (id)groupWithShortName:(NSString *)aShortName {
    id result = [self groupForShortName:aShortName];
    if (result) return result;
    return [self makeGroupWithShortName:aShortName];
}

- (id)userWithShortName:(NSString *)aShortName {
    id result = [self userForShortName:aShortName];
    if (result) return result;
    return [self makeUserWithShortName:aShortName];
}

- (id)dictionaryRepresentation {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setObject:[[_usersByShortName allValues] valueForKeyPath:@"@unionOfObjects.dictionaryRepresentation"] forKey:@"users"];
    [result setObject:[[_groupsByShortName allValues] valueForKeyPath:@"@unionOfObjects.dictionaryRepresentation"] forKey:@"groups"];
    return result;
}

- (void)addEntriesFromDictionaryRepresentation:(NSDictionary *)aDictionary {
    NSEnumerator *representations = nil; 
    NSDictionary *representation = nil;

    representations = [[aDictionary objectForKey:@"groups"] objectEnumerator];
    while ((representation = [representations nextObject])) {
        id entry = [self groupWithShortName:[representation objectForKey:@"shortName"]];
        [entry updateWithDictionaryRepresentation:representation];
    }

    representations = [[aDictionary objectForKey:@"users"] objectEnumerator];
    while ((representation = [representations nextObject])) {
        id entry = [self userWithShortName:[representation objectForKey:@"shortName"]];
        [entry updateWithDictionaryRepresentation:representation];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %d> users:%@, groups:%@",NSStringFromClass([self class]),(int)self,[_usersByShortName allValues],[_groupsByShortName allValues]];
}


@end
