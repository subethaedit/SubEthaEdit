//  TCMMMLogStatisticsEntry.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.

#import <Cocoa/Cocoa.h>

@class TCMMMUser, TCMMMLoggedOperation, TCMMMLoggingState;

@interface TCMMMLogStatisticsEntry : NSObject {
    TCMMMUser *user;
    NSDate *lastActivity;
    BOOL isInside;
    unsigned long operationCount;
    unsigned long deletedCharacters;
    unsigned long insertedCharacters;
    unsigned long selectedCharacters;
    TCMMMLoggingState *loggingState;
}
- (instancetype)initWithMMUser:(TCMMMUser *)aUser;
- (void)updateWithOperation:(TCMMMLoggedOperation *)anOperation;
- (unsigned long)operationCount;
- (unsigned long)deletedCharacters;
- (unsigned long)insertedCharacters;
- (unsigned long)selectedCharacters;
- (TCMMMUser *)user;
- (NSDate *)dateOfLastActivity;
- (TCMMMLoggingState *)loggingState;
- (void)setLoggingState:(TCMMMLoggingState *)aLoggingState;
- (BOOL)isInside;
@end
