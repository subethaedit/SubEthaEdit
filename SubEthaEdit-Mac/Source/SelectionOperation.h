//  SelectionOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import <Foundation/Foundation.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface SelectionOperation : TCMMMOperation <NSCopying> {
    NSRange I_selectedRange;
}

+ (SelectionOperation *)selectionOperationWithRange:(NSRange)aRange userID:(NSString *)aUserID;

@property (nonatomic) NSRange selectedRange;

#pragma mark - methods to conform with the same semantics NSTextView's selectedRanges work
- (NSRange)rangeValue;

@end
