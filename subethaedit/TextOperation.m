//
//  TextOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TextOperation.h"


@implementation TextOperation

+ (void)initialize {
    [TCMMMOperation registerClass:self forOperationType:@"txt"];
}

+ (TextOperation *)textOperationWithAffectedCharRange:(NSRange)aRange replacementString:(NSString *)aString userID:(NSString *)aUserID {
    TextOperation *txtOp = [TextOperation new];
    [txtOp setAffectedCharRange:aRange];
    [txtOp setReplacementString:aString];
    [txtOp setUserID:aUserID];
    return [txtOp autorelease];
}

+ (NSString *)operationID {
    return @"txt";
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super init];
    if (self) {
        I_affectedCharRange.location = [[aDictionary objectForKey:@"loc"] unsignedIntValue];
        I_affectedCharRange.length = [[aDictionary objectForKey:@"len"] unsignedIntValue];
        [self setReplacementString:[aDictionary objectForKey:@"str"]];
        [self setUserID:[aDictionary objectForKey:@"uid"]];
        NSLog(@"operation: %@", [self description]);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    
    [copy setAffectedCharRange:[self affectedCharRange]];
    [copy setReplacementString:[self replacementString]];
    [copy setUserID:[self userID]];
    
    return copy;
}
 
- (void)dealloc {
    [I_replacementString release];
    [I_userID release];
    [super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[self operationID] forKey:TCMMMOperationTypeKey];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_affectedCharRange.location] forKey:@"loc"];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_affectedCharRange.length] forKey:@"len"];
    [dict setObject:[self replacementString] forKey:@"str"];
    if ([self userID]) {
        [dict setObject:[self userID] forKey:@"uid"];
    }
    return dict;
}

- (void)setAffectedCharRange:(NSRange)aRange {
    I_affectedCharRange = aRange;
}

- (NSRange)affectedCharRange {
    return I_affectedCharRange;
}

- (void)setReplacementString:(NSString *)aString {
    [I_replacementString autorelease];
    I_replacementString = [aString copy];
}

- (NSString *)replacementString {
    return I_replacementString;
}

- (void)setUserID:(NSString *)aUserID {
    [I_userID autorelease];
    I_userID = [aUserID copy];
}

- (NSString *)userID {
    return I_userID;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"affectedRange: %@; string: %@; byUser: %@", NSStringFromRange([self affectedCharRange]), [self replacementString], [self userID]];
}

@end
