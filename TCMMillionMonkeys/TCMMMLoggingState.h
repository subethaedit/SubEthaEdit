//
//  TCMMMLoggingState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMMMState.h"


@interface TCMMMLoggingState : TCMMMState {
    NSMutableArray *I_loggedOperations;
    NSMutableSet *I_participantIDs;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;
- (NSSet *)participantIDs;

@end
