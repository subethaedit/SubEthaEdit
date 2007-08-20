//
//  TCMMMLoggingState.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMLoggingState.h"
#import "TCMMMLoggedOperation.h"
#import "TCMMMNoOperation.h"

@implementation TCMMMLoggingState

- (id)init {
    if ((self=[super initAsServer:NO])) {
        [self setIsSendingNoOps:NO];
        I_loggedOperations = [NSMutableArray new];
        I_participantIDs   = [NSMutableSet new];
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    if ((self=[self init])) {
        NSEnumerator *operationReps = [[aDictionary objectForKey:@"ops"] objectEnumerator];
        NSDictionary *operationRep =nil;
        while ((operationRep = [operationReps nextObject])) {
            id operation = [[[TCMMMLoggedOperation alloc] initWithDictionaryRepresentation:operationRep] autorelease];
            if (operation) {
                NSString *userID = [[operation operation] userID];
                if (userID) {
                    [I_participantIDs addObject:userID];
                }
                [I_loggedOperations addObject:operation];
            }
        }
    }
    NSLog(@"%s imported %d operations, the last one being:%@",__FUNCTION__,[I_loggedOperations count],[I_loggedOperations lastObject]);
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictRep = [NSMutableDictionary dictionary];
    NSMutableArray *operationReps = [NSMutableArray array];
    NSEnumerator *operations = [I_loggedOperations objectEnumerator];
    TCMMMLoggedOperation *operation = nil;
    while ((operation=[operations nextObject])) {
        [operationReps addObject:[operation dictionaryRepresentation]];
    }
    [dictRep setObject:operationReps forKey:@"ops"];
    return dictRep;
}

- (void)dealloc {
    [I_loggedOperations release];
    [I_participantIDs release];
    [super dealloc];
}

- (void)handleOperation:(TCMMMOperation *)anOperation {
    TCMMMLoggedOperation *previousLoggedOperation = [I_loggedOperations lastObject];
    if ([[anOperation operationID] isEqualToString:[TCMMMNoOperation operationID]] || 
        [anOperation isEqualTo:[previousLoggedOperation operation]]) {
        NSLog(@"%s not logging Operation:%@",__FUNCTION__,anOperation);
    } else {
        TCMMMLoggedOperation *operation=[TCMMMLoggedOperation loggedOperationWithOperation:anOperation index:[previousLoggedOperation index]+1];
        id userID = [anOperation userID];
        if (userID) {
            [I_participantIDs addObject:userID];
        }
        [I_loggedOperations addObject:operation];
    }
}

- (NSSet *)participantIDs {
    return I_participantIDs;
}

@end
