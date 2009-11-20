//
//  SDDirectory.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.05.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDDirectoryEntry.h"
#import "SDDirectoryUser.h"
#import "SDDirectoryGroup.h"

extern NSString * const kSDDirectoryGroupEveryoneGroupShortName;

extern NSString * const kSDDirectoryAdminRole;
extern NSString * const kSDDirectoryConfidantRole;
extern NSString * const kSDDirectoryGuestRole;

@class SDDirectoryEntry,SDDirectoryUser,SDDirectoryGroup;

@interface SDDirectory : NSObject {
    NSMutableDictionary *_usersByShortName;
    NSMutableDictionary *_groupsByShortName;
}

+ (id)sharedInstance;
- (id)dictionaryRepresentation;
- (id)shortDictionaryRepresentation;

- (void)addEntriesFromDictionaryRepresentation:(NSDictionary *)aDictionary;

- (id)userForShortName:(NSString *)aShortName;
- (id)groupForShortName:(NSString *)aShortName;
- (id)makeUserWithShortName:(NSString *)aShortName;
- (id)makeGroupWithShortName:(NSString *)aShortName;

// these methods generate entries if none are found
- (id)userWithShortName:(NSString *)aShortName;
- (id)groupWithShortName:(NSString *)aShortName;

@end
