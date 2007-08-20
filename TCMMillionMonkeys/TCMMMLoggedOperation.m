//
//  TCMMMLoggingState.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMLoggedOperation.h"


@implementation TCMMMLoggedOperation

+ (id)loggedOperationWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex {
    return [[[TCMMMLoggedOperation alloc] initWithOperation:anOperation index:anIndex] autorelease];
}


- (id)initWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex{
    if ((self=[super init])) {
        I_op = [anOperation copy];
        I_date = [[NSCalendarDate alloc] init];
        I_index = anIndex;
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super init];
    if (self) {
        I_date = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate:[[aDictionary objectForKey:@"t"] doubleValue]/100.];
        I_op = [[TCMMMOperation operationWithDictionaryRepresentation:[aDictionary objectForKey:@"op"]] retain];
        I_index = [[aDictionary objectForKey:@"i"] longLongValue];
        NSAssert(I_op,@"operation was nill");
        //NSLog(@"message: %@",[self description]);
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *representation = [NSMutableDictionary dictionary];
    [representation setObject:[[self operation] dictionaryRepresentation]
                       forKey:@"op"];
    [representation setObject:[NSNumber numberWithDouble:[I_date timeIntervalSinceReferenceDate]*100.] forKey:@"t"];
    [representation setObject:[NSNumber numberWithLongLong:I_index] forKey:@"i"];
    return representation;
}

- (TCMMMOperation *)operation {
    return I_op;
}

- (NSCalendarDate *)date {
    return I_date;
}

- (long long)index {
    return I_index;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@\ntime: %f\nop: %@\nindex:%u", [self class],[I_date timeIntervalSinceReferenceDate],I_op,I_index];
}


- (void)dealloc {
    [I_op release];
     I_op = nil;
    [I_date release];
     I_date = nil;
    [super dealloc];
}


@end
