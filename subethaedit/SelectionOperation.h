//
//  SelectionOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface SelectionOperation : TCMMMOperation {
    NSRange I_selectedRange;
    NSString *I_userID;
}

+ (SelectionOperation *)selectionOperationWithRange:(NSRange)aRange userID:(NSString *)aUserID;

- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)aRange;
- (NSString *)userID;
- (void)setUserID:(NSString *)aUserID;

@end
