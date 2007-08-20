//
//  TCMMMLoggingState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMMMOperation.h"


@interface TCMMMLoggedOperation : NSObject {
    TCMMMOperation *I_op;
    NSCalendarDate *I_date;
    long long I_index;
}

+ (id)loggedOperationWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex;
- (id)initWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex;
- (id)initWithDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSDictionary *)dictionaryRepresentation;
- (NSCalendarDate *)date;
- (TCMMMOperation *)operation;
- (long long)index;
@end
