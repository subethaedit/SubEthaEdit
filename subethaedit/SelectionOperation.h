//
//  SelectionOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface SelectionOperation : TCMMMOperation <NSCopying> {
    NSRange I_selectedRange;
}

+ (SelectionOperation *)selectionOperationWithRange:(NSRange)aRange userID:(NSString *)aUserID;

- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)aRange;

@end
