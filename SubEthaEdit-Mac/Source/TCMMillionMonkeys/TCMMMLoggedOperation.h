//  TCMMMLoggingState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.

#import <Cocoa/Cocoa.h>
#import "TCMMMOperation.h"


@interface TCMMMLoggedOperation : NSObject {
    TCMMMOperation *I_op;
    NSDate *I_date;
    long long I_index;
	NSDictionary *I_replacedAttributedStringDictionaryRepresentation;
}

+ (id)loggedOperationWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex;
- (id)initWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex;
- (id)initWithDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (void)setReplacedAttributedStringDictionaryRepresentation:(NSDictionary *)aReplacedAttributedStringDictionaryRepresentation;
- (NSDictionary *)replacedAttributedStringDictionaryRepresentation;

- (NSDictionary *)dictionaryRepresentation;
- (void)setDate:(NSDate *)aDate;
- (NSDate *)date;
- (TCMMMOperation *)operation;
- (long long)index;
@end
