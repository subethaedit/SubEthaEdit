//  TCMMMLoggingState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 20.08.07.

#import <Cocoa/Cocoa.h>
#import "TCMMMOperation.h"


@interface TCMMMLoggedOperation : NSObject 

@property (nonatomic, strong) NSDate *date;

+ (id)loggedOperationWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex;
- (instancetype)initWithOperation:(TCMMMOperation *)anOperation index:(long long)anIndex;
- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (void)setReplacedAttributedStringDictionaryRepresentation:(NSDictionary *)aReplacedAttributedStringDictionaryRepresentation;
- (NSDictionary *)replacedAttributedStringDictionaryRepresentation;

- (NSDictionary *)dictionaryRepresentation;
- (TCMMMOperation *)operation;
- (long long)index;
@end
