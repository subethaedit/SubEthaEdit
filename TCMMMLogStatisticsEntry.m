//
//  TCMMMLogStatisticsEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMLogStatisticsEntry.h"
#import "TCMMMUser.h"
#import "TCMMMLoggedOperation.h"
#import "SelectionOperation.h"
#import "TextOperation.h"

@interface TCMMMLogStatisticsEntry (TCMMMLogStatisticsEntryPrivateAdditions)
- (void)setDateOfLastActivity:(NSCalendarDate *)aDate;
@end

@implementation TCMMMLogStatisticsEntry
+ (void)initialize {
    [self setKeys:[NSArray arrayWithObject:@"dateOfLastActivity"] triggerChangeNotificationsForDependentKey:@"operationCount"];
    [self setKeys:[NSArray arrayWithObject:@"dateOfLastActivity"] triggerChangeNotificationsForDependentKey:@"deletedCharacters"];
    [self setKeys:[NSArray arrayWithObject:@"dateOfLastActivity"] triggerChangeNotificationsForDependentKey:@"insertedCharacters"];
    [self setKeys:[NSArray arrayWithObject:@"dateOfLastActivity"] triggerChangeNotificationsForDependentKey:@"selectedCharacters"];
}

- (id)initWithMMUser:(TCMMMUser *)aUser {
    if ((self=[super init])) {
        [self setDateOfLastActivity:[NSCalendarDate distantPast]];
        user = [aUser retain];
    }
    return self;
}

// only for usage in a tableview cell
- (id)copyWithZone:(NSZone *)aZone {
    return [self retain];
}

- (void)dealloc {
    [lastActivity release];
    [user release];
    [super dealloc];
}

- (void)updateWithOperation:(TCMMMLoggedOperation *)anOperation {
    id op = [anOperation operation];
    NSAssert([[op userID] isEqualToString:[user userID]],@"Updating this user with an operation from another User");
    if ([[anOperation date] timeIntervalSinceDate:lastActivity]>0) {
        [self setDateOfLastActivity:[anOperation date]];
    }
    operationCount++;
    if ([[op operationID] isEqualToString:[TextOperation operationID]]) {
        deletedCharacters+=[op affectedCharRange].length;
        insertedCharacters+=[[op replacementString] length];
    } else if ([[op operationID] isEqualToString:[SelectionOperation operationID]]) {
        selectedCharacters+=[op selectedRange].length;
    }
}
- (unsigned long)operationCount {
    return operationCount;
}
- (unsigned long)deletedCharacters {
    return deletedCharacters;
}
- (unsigned long)insertedCharacters {
    return insertedCharacters;
}
- (unsigned long)selectedCharacters {
    return selectedCharacters;
}
- (void)setDateOfLastActivity:(NSCalendarDate *)aDate {
    [self willChangeValueForKey:@"dateOfLastActivity"];
    [lastActivity autorelease];
     lastActivity = [aDate retain];
    [self didChangeValueForKey:@"dateOfLastActivity"];
}
- (TCMMMUser *)user {
    return user;
}
- (NSCalendarDate *)dateOfLastActivity {
    return lastActivity;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ user:%@ lastActivity:%@ opCount:%u delChar:%u insChar:%u selChar:%u",[self class],[self user],lastActivity,operationCount,deletedCharacters,insertedCharacters,selectedCharacters];
}
@end
