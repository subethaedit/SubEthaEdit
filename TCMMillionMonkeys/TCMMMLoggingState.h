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
    NSMutableArray *I_statisticsArray;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSSet *)participantIDs;
- (NSArray *)statisticsArray;
- (TCMMMLogStatisticsEntry *)statisicsEntryForUserID:(NSString *)aUserID;

@end
