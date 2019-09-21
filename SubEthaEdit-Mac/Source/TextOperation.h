//  TextOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 24 2004.

#import <Foundation/Foundation.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface TextOperation : TCMMMOperation <NSCopying> 

@property (nonatomic) NSRange affectedCharRange;
@property (nonatomic, copy) NSString *replacementString;

+ (TextOperation *)textOperationWithAffectedCharRange:(NSRange)aRange replacementString:(NSString *)aString userID:(NSString *)aUserID;

- (BOOL)isIrrelevant;
- (BOOL)shouldBeGroupedWithTextOperation:(TextOperation *)priorOperation;


@end
