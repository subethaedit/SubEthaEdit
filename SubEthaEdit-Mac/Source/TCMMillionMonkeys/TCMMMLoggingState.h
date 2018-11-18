//  TCMMMLoggingState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.

#import <Cocoa/Cocoa.h>
#import "TCMMMSession.h"
#import "TCMMMState.h"
#import "TCMMMLogStatisticsEntry.h"

@class TCMMMSession;

@interface TCMMMLoggingState : TCMMMState {
    NSMutableArray *I_loggedOperations;
    NSMutableSet *I_participantIDs;
    NSMutableDictionary *I_statisticsEntryByUserID;
    TCMMutableBencodedData *I_initialTextStorageDictionaryRepresentation;
    TCMMutableBencodedData *I_bencodedLoggedOperations;
    NSMutableArray *I_statisticsArray;
    unsigned long operationCount;
    unsigned long deletedCharacters;
    unsigned long insertedCharacters;
    unsigned long selectedCharacters;
    NSMutableArray *I_statisticsData;
    TCMMMSession *I_MMSession;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationForSaving;
- (void)makeAllParticipantsLeave;
- (NSSet *)participantIDs;
- (NSArray *)statisticsArray;
- (TCMMMLogStatisticsEntry *)statisicsEntryForUserID:(NSString *)aUserID;
- (NSArray *)loggedOperations;

- (void)addOperationsForAttributedStringState:(NSAttributedString *)anAttributedString;


- (unsigned long)operationCount;
- (unsigned long)deletedCharacters;
- (unsigned long)insertedCharacters;
- (unsigned long)selectedCharacters;
- (NSArray *)statisticsData;

- (void)setMMSession:(TCMMMSession *)aSession;
- (TCMMMSession *)MMSession;


// depricated - if encountered should be converted on receiving
- (void)setInitialTextStorageDictionaryRepresentation:(NSDictionary *)aInitialRepresentation;
- (NSDictionary *)initialTextStorageDictionaryRepresentation;


@end
