//
//  TCMMMLoggingState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMMMState.h"
#import "TCMMMLogStatisticsEntry.h"


@interface TCMMMLoggingState : TCMMMState {
    NSMutableArray *I_loggedOperations;
    NSMutableSet *I_participantIDs;
    NSMutableDictionary *I_statisticsEntryByUserID;
    NSDictionary *I_initialTextStorageDictionaryRepresentation;
    NSMutableArray *I_statisticsArray;
    unsigned long operationCount;
    unsigned long deletedCharacters;
    unsigned long insertedCharacters;
    unsigned long selectedCharacters;
    NSMutableArray *I_statisticsData;
    
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationForSaving;
- (void)makeAllParticipantsLeave;
- (NSSet *)participantIDs;
- (NSArray *)statisticsArray;
- (TCMMMLogStatisticsEntry *)statisicsEntryForUserID:(NSString *)aUserID;
- (NSArray *)loggedOperations;
- (void)setInitialTextStorageDictionaryRepresentation:(NSDictionary *)aInitialRepresentation;
- (NSDictionary *)initialTextStorageDictionaryRepresentation;
- (unsigned long)operationCount;
- (unsigned long)deletedCharacters;
- (unsigned long)insertedCharacters;
- (unsigned long)selectedCharacters;
- (NSArray *)statisticsData;

@end
