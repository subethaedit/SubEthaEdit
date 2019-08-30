//  TCMMMLoggingState.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.

#import "TCMMMLoggedOperation.h"

@implementation TCMMMLoggedOperation {
    TCMMMOperation *I_op;
    long long I_index;
    NSDictionary *I_replacedAttributedStringDictionaryRepresentation;
}

+ (id)loggedOperationWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex {
    return [[TCMMMLoggedOperation alloc] initWithOperation:anOperation index:anIndex];
}

- (instancetype)initWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex{
    if ((self=[super init])) {
        I_op = [anOperation copy];
        _date = [[NSDate alloc] init];
        I_index = anIndex;
    }
    return self;
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super init];
    if (self) {
        _date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:[[aDictionary objectForKey:@"t"] doubleValue]/100.];
        I_op = [TCMMMOperation operationWithDictionaryRepresentation:[aDictionary objectForKey:@"op"]];
        I_index = [[aDictionary objectForKey:@"i"] longLongValue];
        I_replacedAttributedStringDictionaryRepresentation = [aDictionary objectForKey:@"rstr"];
        NSAssert(I_op,@"operation was nil");
        //NSLog(@"message: %@",[self description]);
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *representation = [NSMutableDictionary dictionary];
    [representation setObject:[[self operation] dictionaryRepresentation]
                       forKey:@"op"];
    [representation setObject:[NSNumber numberWithDouble:[_date timeIntervalSinceReferenceDate]*100.] forKey:@"t"];
    [representation setObject:[NSNumber numberWithLongLong:I_index] forKey:@"i"];
    if (I_replacedAttributedStringDictionaryRepresentation) {
    	[representation setObject:I_replacedAttributedStringDictionaryRepresentation forKey:@"rstr"];
    }
    return representation;
}

- (TCMMMOperation *)operation {
    return I_op;
}

- (void)setReplacedAttributedStringDictionaryRepresentation:(NSDictionary *)aReplacedAttributedStringDictionaryRepresentation {
	if ([(NSString *)[aReplacedAttributedStringDictionaryRepresentation objectForKey:@"String"] length] == 0) {
		aReplacedAttributedStringDictionaryRepresentation = nil;
	}
	 I_replacedAttributedStringDictionaryRepresentation = aReplacedAttributedStringDictionaryRepresentation;
}

- (NSDictionary *)replacedAttributedStringDictionaryRepresentation {
	return I_replacedAttributedStringDictionaryRepresentation;
}

- (long long)index {
    return I_index;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@\ntime: %f\nop: %@\nindex:%lld", [self class],[_date timeIntervalSinceReferenceDate],I_op,I_index];
}

@end
