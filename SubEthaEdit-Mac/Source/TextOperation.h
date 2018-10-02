//  TextOperation.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 24 2004.

#import <Foundation/Foundation.h>
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"


@interface TextOperation : TCMMMOperation <NSCopying> {
    NSRange I_affectedCharRange;
    NSString *I_replacementString;
}

+ (TextOperation *)textOperationWithAffectedCharRange:(NSRange)aRange replacementString:(NSString *)aString userID:(NSString *)aUserID;

- (void)setAffectedCharRange:(NSRange)aRange;
- (NSRange)affectedCharRange;
- (void)setReplacementString:(NSString *)aString;
- (NSString *)replacementString;
- (BOOL)isIrrelevant;
- (BOOL)shouldBeGroupedWithTextOperation:(TextOperation *)priorOperation;


@end
