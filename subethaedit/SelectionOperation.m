//
//  SelectionOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SelectionOperation.h"


@implementation SelectionOperation

+ (void)initialize {
    [TCMMMOperation registerClass:self forOperationType:@"sel"];
}

+ (SelectionOperation *)selectionOperationWithRange:(NSRange)aRange userID:(NSString *)aUserID {
    SelectionOperation *result = [[SelectionOperation new] autorelease];
    [result setSelectedRange:aRange];
    [result setUserID:aUserID];
    return result;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super init];
    if (self) {
        I_selectedRange.location = [[aDictionary objectForKey:@"loc"] unsignedIntValue];
        I_selectedRange.length   = [[aDictionary objectForKey:@"len"] unsignedIntValue];
        [self setUserID:[aDictionary objectForKey:@"uid"]];
        NSLog(@"operation: %@",[self description]);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    
    [copy setUserID:[self userID]];
    [copy setSelectedRange:[self selectedRange]];
    
    return copy;
}

- (void)dealloc {
    [I_userID release];
    [super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"sel" forKey:TCMMMOperationTypeKey];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_selectedRange.location] forKey:@"loc"];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_selectedRange.length] forKey:@"len"];
    if ([self userID]) {
        [dict setObject:[self userID] forKey:@"uid"];
    }
    return dict;
}

- (NSRange)selectedRange {
    return I_selectedRange;
}

- (void)setSelectedRange:(NSRange)aRange {
    I_selectedRange = aRange;
}

- (NSString *)userID {
    return I_userID;
}

- (void)setUserID:(NSString *)aUserID {
    [I_userID autorelease];
    I_userID = [aUserID copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"selectedRange: %@; byUser: %@", NSStringFromRange([self selectedRange]), [self userID]];
}

@end
