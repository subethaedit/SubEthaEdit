//
//  TCMMMLogStatisticsEntry.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMUser, TCMMMLoggedOperation;

@interface TCMMMLogStatisticsEntry : NSObject {
    TCMMMUser *user;
    NSCalendarDate *lastActivity;
    unsigned long operationCount;
    unsigned long deletedCharacters;
    unsigned long insertedCharacters;
    unsigned long selectedCharacters;
}
- (id)initWithMMUser:(TCMMMUser *)aUser;
- (void)updateWithOperation:(TCMMMLoggedOperation *)anOperation;
- (unsigned long)operationCount;
- (unsigned long)deletedCharacters;
- (unsigned long)insertedCharacters;
- (unsigned long)selectedCharacters;
- (TCMMMUser *)user;
- (NSCalendarDate *)dateOfLastActivity;
@end
