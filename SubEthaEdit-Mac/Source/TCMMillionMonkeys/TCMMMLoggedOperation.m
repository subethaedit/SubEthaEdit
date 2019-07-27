//  TCMMMLoggingState.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.

#import "TCMMMLoggedOperation.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@implementation TCMMMLoggedOperation

+ (id)loggedOperationWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex {
    return [[TCMMMLoggedOperation alloc] initWithOperation:anOperation index:anIndex];
}


- (id)initWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex{
    if ((self=[super init])) {
        I_op = [anOperation copy];
        I_date = [[NSDate alloc] init];
        I_index = anIndex;
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super init];
    if (self) {
        I_date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:[[aDictionary objectForKey:@"t"] doubleValue]/100.];
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
    [representation setObject:[NSNumber numberWithDouble:[I_date timeIntervalSinceReferenceDate]*100.] forKey:@"t"];
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


- (void)setDate:(NSDate *)aDate {
     I_date = aDate;
}


- (NSDate *)date {
    return I_date;
}

- (long long)index {
    return I_index;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@\ntime: %f\nop: %@\nindex:%lld", [self class],[I_date timeIntervalSinceReferenceDate],I_op,I_index];
}


- (void)dealloc {
     I_op = nil;
     I_date = nil;
     I_replacedAttributedStringDictionaryRepresentation = nil;
}


@end
