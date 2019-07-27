//  TCMMMLogStatisticsEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.

#import "TCMMMLogStatisticsEntry.h"
#import "TCMMMLoggingState.h"
#import "TCMMMUser.h"
#import "TCMMMLoggedOperation.h"
#import "SelectionOperation.h"
#import "TextOperation.h"
#import "UserChangeOperation.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@interface TCMMMLogStatisticsEntry (TCMMMLogStatisticsEntryPrivateAdditions)
- (void)setDateOfLastActivity:(NSDate *)aDate;
@end

@implementation TCMMMLogStatisticsEntry

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)aKey {
	NSSet *result = [super keyPathsForValuesAffectingValueForKey:aKey];
	static NSSet *S_dateAffectingSet = nil;
	if (!S_dateAffectingSet) S_dateAffectingSet = [[NSSet alloc] initWithObjects:@"operationCount",@"deletedCharacters",@"insertedCharacters",@"selectedCharacters",nil];
	if ([S_dateAffectingSet containsObject:aKey]) {
		result = [result setByAddingObject:@"dateOfLastActivity"];
	}
	return result;
}

- (id)initWithMMUser:(TCMMMUser *)aUser {
    if ((self=[super init])) {
        [self setDateOfLastActivity:[NSDate distantPast]];
        user = aUser;
    }
    return self;
}

// only for usage in a tableview cell
- (id)copyWithZone:(NSZone *)aZone {
    return self;
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
        isInside = YES;
    } else if ([[op operationID] isEqualToString:[SelectionOperation operationID]]) {
        selectedCharacters+=[op selectedRange].length;
        isInside = YES;
    } else if ([[op operationID] isEqualToString:[UserChangeOperation operationID]]) {
        if ([(UserChangeOperation *)op type] == UserChangeTypeLeave) {
            isInside = NO;
        } else {
            isInside = YES;
        }
    }
}

- (BOOL)isInside {
    return isInside;
}

- (TCMMMLoggingState *)loggingState {
    return self->loggingState;
}

- (void)setLoggingState:(TCMMMLoggingState *)aLoggingState {
    self->loggingState = aLoggingState;
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
- (void)setDateOfLastActivity:(NSDate *)aDate {
    [self willChangeValueForKey:@"dateOfLastActivity"];
     lastActivity = aDate;
    [self didChangeValueForKey:@"dateOfLastActivity"];
}
- (TCMMMUser *)user {
    return user;
}
- (NSDate *)dateOfLastActivity {
    return lastActivity;
}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ user:%@ lastActivity:%@ opCount:%lu delChar:%lu insChar:%lu selChar:%lu",[self class],[self user],lastActivity,operationCount,deletedCharacters,insertedCharacters,selectedCharacters];
}
@end
