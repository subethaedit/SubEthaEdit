//  TCMMMLoggingState.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.

#import "TCMMMLoggingState.h"
#import "TCMMMLoggedOperation.h"
#import "TCMMMNoOperation.h"
#import "TCMMMUserManager.h"
#import "TCMMMLogStatisticsEntry.h"
#import "SelectionOperation.h"
#import "TextOperation.h"
#import "UserChangeOperation.h"
#import "TCMMMLogStatisticsDataPoint.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"
#import "NSMutableAttributedStringSEEAdditions.h"

@interface TCMMMLoggingState (TCMMMLoggingStatePrivateAdditions)
- (void)addLoggedOperation:(TCMMMLoggedOperation *)anOperation;
@end

@implementation TCMMMLoggingState

- (instancetype)init {
    if ((self=[super initAsServer:NO])) {
        [self setIsSendingNoOps:NO];
        I_loggedOperations = [NSMutableArray new];
        I_bencodedLoggedOperations = [[TCMMutableBencodedData alloc] initWithObject:I_loggedOperations];
        I_participantIDs   = [NSMutableSet new];
        I_statisticsArray  = [NSMutableArray new];
        I_statisticsEntryByUserID = [NSMutableDictionary new];
        I_statisticsData = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    if ((self=[self init])) {
        NSEnumerator *operationReps = [[aDictionary objectForKey:@"ops"] objectEnumerator];
        NSDictionary *operationRep =nil;
        NSMutableArray *loggedOperations = [NSMutableArray array];
        while ((operationRep = [operationReps nextObject])) {
            id operation = [[[TCMMMLoggedOperation alloc] initWithDictionaryRepresentation:operationRep] autorelease];
            if (operation) {
                [loggedOperations addObject:operation];
                NSString *userID = [[operation operation] userID];
                if (userID) {
                    [I_participantIDs addObject:userID];
                }
            }
        }
    
        // check if times are plausible if not move all operations backwards
        NSDate *referenceDate = [[loggedOperations lastObject] date];
        NSTimeInterval timeDifference = 0.0;
        if (referenceDate) {
            NSTimeInterval timeSinceNow = [referenceDate timeIntervalSinceNow];
            if (timeSinceNow > 0) {
                timeDifference = -timeSinceNow;
            }
        }
        
		// check if we have an initial text representation - if we have take it in and add the reverse operations to the textoperations
		// this is to support loading of old seetext information that was based on that
		NSMutableAttributedString *initialText = nil;
        if ([aDictionary objectForKey:@"initialtext"]) {
        	initialText = [NSMutableAttributedString new];
        	[initialText setContentByDictionaryRepresentation:[aDictionary objectForKey:@"initialtext"]];
        }

        for (TCMMMLoggedOperation *operation in loggedOperations) {
            if (timeDifference < 0) {
                [operation setDate:[[operation date] dateByAddingTimeInterval:timeDifference]];
            }
            id innerOperation = [operation operation];
            if (initialText && [innerOperation isKindOfClass:[TextOperation class]]) {
            	NSRange affectedCharRange = [innerOperation affectedCharRange];
            	if (affectedCharRange.length > 0 && NSMaxRange(affectedCharRange) <= [initialText length]) {
            		[operation setReplacedAttributedStringDictionaryRepresentation:[[initialText attributedSubstringFromRange:affectedCharRange] dictionaryRepresentation]];
            	}
				id userID = [innerOperation userID];
				NSString *replacementString = [innerOperation replacementString];
				NSRange newRange = NSMakeRange(affectedCharRange.location,[replacementString length]);
				[initialText replaceCharactersInRange:affectedCharRange
										   withString:replacementString];
				[initialText addAttribute:WrittenByUserIDAttributeName value:userID range:newRange];
				[initialText addAttribute:ChangedByUserIDAttributeName value:userID range:newRange];
            }
            [self addLoggedOperation:operation];
        }
        if (initialText) {
        	[initialText release];
        }
		DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel,@"imported %ld operations, the last one being:%@ statistics are:%@",(unsigned long)[I_loggedOperations count],[I_loggedOperations lastObject],I_statisticsArray);
    }
    return self;
}

- (void)makeAllParticipantsLeave {
    NSEnumerator *statisticsEntries = [I_statisticsEntryByUserID objectEnumerator];
    TCMMMLogStatisticsEntry *entry = nil;
    while ((entry = [statisticsEntries nextObject])) {
        if ([entry isInside]) {
            TCMMMOperation *op = [UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:[[entry user] userID] newGroup:TCMMMSessionPoofGroupName];
            [self handleOperation:op];
        }
    }
}

- (NSDictionary *)dictionaryRepresentationForSaving {
    NSMutableDictionary *dictRep = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryRepresentation]];
    NSMutableArray *leaveOperations = [NSMutableArray array];
    NSEnumerator *statisticsEntries = [I_statisticsEntryByUserID objectEnumerator];
    TCMMMLogStatisticsEntry *entry = nil;
    long long index = [(TCMMMLoggedOperation *)[I_loggedOperations lastObject] index];
    while ((entry = [statisticsEntries nextObject])) {
        if ([entry isInside]) {
            TCMMMLoggedOperation *op = [TCMMMLoggedOperation loggedOperationWithOperation:[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:[[entry user] userID] newGroup:TCMMMSessionPoofGroupName] index:++index];
            [leaveOperations addObject:[op dictionaryRepresentation]];
        }
    }
    [dictRep setObject:[[dictRep objectForKey:@"ops"] mutableBencodedDataByAppendingObjectsFromArrayToBencodedArray:leaveOperations] forKey:@"ops"];
    return dictRep;
}


- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictRep = [NSMutableDictionary dictionary];
    [dictRep setObject:I_bencodedLoggedOperations forKey:@"ops"];
    if (I_initialTextStorageDictionaryRepresentation) {
        // NSLog(@"%s save initial text:%@",__FUNCTION__,I_initialTextStorageDictionaryRepresentation);
        [dictRep setObject:I_initialTextStorageDictionaryRepresentation forKey:@"initialtext"];
    }
    return dictRep;
}

- (void)dealloc {
    [I_statisticsEntryByUserID release];
    [I_statisticsArray release];
    [I_loggedOperations release];
    [I_bencodedLoggedOperations release];
    [I_participantIDs release];
    [I_statisticsData release];
    [I_initialTextStorageDictionaryRepresentation release];
    [super dealloc];
}

- (void)handleOperation:(TCMMMOperation *)anOperation {
    TCMMMLoggedOperation *previousLoggedOperation = [I_loggedOperations lastObject];
    if ([[anOperation operationID] isEqualToString:[TCMMMNoOperation operationID]] || 
        [anOperation isEqualTo:[previousLoggedOperation operation]]) {
        //NSLog(@"%s not logging Operation:%@",__FUNCTION__,anOperation);
    } else {
        TCMMMLoggedOperation *operation=[TCMMMLoggedOperation loggedOperationWithOperation:anOperation index:[previousLoggedOperation index]+1];
        id userID = [anOperation userID];
        if (userID) {
            [I_participantIDs addObject:userID];
        }
        if ([[anOperation operationID] isEqualToString:[TextOperation operationID]]) {
        	[operation setReplacedAttributedStringDictionaryRepresentation:[[I_MMSession lastReplacedAttributedString] dictionaryRepresentation]];
        }
        [self addLoggedOperation:operation];
    }
}

- (void)addLoggedOperation:(TCMMMLoggedOperation *)anOperation {
    [I_bencodedLoggedOperations appendObjectToBencodedArray:[anOperation dictionaryRepresentation]];
    [I_loggedOperations addObject:anOperation];
    NSString *userID = [[anOperation operation] userID];
    if (userID) {
        TCMMMLogStatisticsEntry *statisticsEntry = [self statisicsEntryForUserID:userID];
        if (!statisticsEntry) {
            TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:userID];
            if (!user) {
                NSLog(@"%s cannot generate stats for unknown user: %@",__FUNCTION__,userID);
            } else {
                NSIndexSet *changeSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([I_statisticsArray count],1)];
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:changeSet forKey:@"statisticsArray"];
                statisticsEntry = [[[TCMMMLogStatisticsEntry alloc] initWithMMUser:user] autorelease];
                
                [I_statisticsEntryByUserID setObject:statisticsEntry forKey:userID];
                [I_statisticsArray addObject:statisticsEntry];
                [statisticsEntry setLoggingState:self];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:changeSet forKey:@"statisticsArray"];
            }
        }
        NSIndexSet *changeSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_statisticsArray count])];
        [self willChange:NSKeyValueChangeSetting valuesAtIndexes:changeSet forKey:@"statisticsArray"];
        [statisticsEntry updateWithOperation:anOperation];
        id op = [anOperation operation];
            if ([[op operationID] isEqualToString:[TextOperation operationID]]) {
            deletedCharacters+=[op affectedCharRange].length;
            insertedCharacters+=[[op replacementString] length];
        } else if ([[op operationID] isEqualToString:[SelectionOperation operationID]]) {
            selectedCharacters+=[op selectedRange].length;
        }
        [self didChange:NSKeyValueChangeSetting valuesAtIndexes:changeSet forKey:@"statisticsArray"];
        
        NSMutableDictionary *dataEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [anOperation date], @"date",
            nil];
        [dataEntry setObject:[[[TCMMMLogStatisticsDataPoint alloc] initWithDataObject:self] autorelease] forKey:@"document"];
        unsigned count = [I_statisticsArray count];
        while (count--) {
            TCMMMLogStatisticsEntry *entry = [I_statisticsArray objectAtIndex:count];
            [dataEntry setObject:[[[TCMMMLogStatisticsDataPoint alloc] initWithDataObject:entry] autorelease] forKey:[[entry user] userID]];
        }
        [I_statisticsData addObject:dataEntry];
    }
}

- (NSArray *)statisticsData {
    return I_statisticsData;
}

- (TCMMMLogStatisticsEntry *)statisicsEntryForUserID:(NSString *)aUserID {
    return [I_statisticsEntryByUserID objectForKey:aUserID];
}

- (NSSet *)participantIDs {
    return I_participantIDs;
}

- (NSArray *)statisticsArray {
    return I_statisticsArray;
}

- (NSArray *)loggedOperations {
    return I_loggedOperations;
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


- (void)addOperationsForAttributedStringState:(NSAttributedString *)anAttributedString {
    NSRange wholeRange = NSMakeRange(0,[anAttributedString length]);
    NSMutableSet *userSet=[NSMutableSet set];
    if (wholeRange.length) {
        NSRange searchRange=NSMakeRange(0,0);
        while (NSMaxRange(searchRange)<wholeRange.length) {
            id value=[anAttributedString attribute:WrittenByUserIDAttributeName atIndex:NSMaxRange(searchRange) 
                   longestEffectiveRange:&searchRange inRange:wholeRange];
            if (value) {
                [self handleOperation:[TextOperation textOperationWithAffectedCharRange:searchRange replacementString:[[anAttributedString string] substringWithRange:searchRange] userID:value]];
                [userSet addObject:value];
            }
        }
        [self makeAllParticipantsLeave]; // so they don't appear as inside the document when they aren't
    }
}


- (void)setMMSession:(TCMMMSession *)aSession {
	I_MMSession = aSession;
}
- (TCMMMSession *)MMSession {
	return I_MMSession;
}



// deprecated
- (void)setInitialTextStorageDictionaryRepresentation:(NSDictionary *)aInitialRepresentation {
    [I_initialTextStorageDictionaryRepresentation autorelease];
     I_initialTextStorageDictionaryRepresentation = [[TCMMutableBencodedData alloc] initWithObject:aInitialRepresentation];
}

- (NSDictionary *)initialTextStorageDictionaryRepresentation {
    return [I_initialTextStorageDictionaryRepresentation decodedObject];
}



@end
