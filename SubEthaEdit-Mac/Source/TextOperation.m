//  TextOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 24 2004.

#import "TextOperation.h"


@implementation TextOperation

+ (void)initialize {
	if (self == [TextOperation class]) {
	    [TCMMMOperation registerClass:self forOperationType:[self operationID]];
	}
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

+ (void)transformTextOperation:(TextOperation *)aClientOperation serverTextOperation:(TextOperation *)aServerOperation {
   DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel, @"transformText: %@, %@", [aClientOperation description], [aServerOperation description]);
    
    if (DisjointRanges([aClientOperation affectedCharRange], [aServerOperation affectedCharRange])) {
        // non-conflicting operations

        if ([aServerOperation affectedCharRange].location > [aClientOperation affectedCharRange].location) {
            // server operation range after local operation range
            NSRange newRange = [aServerOperation affectedCharRange];
            newRange.location -= [aClientOperation affectedCharRange].length;
            newRange.location += [[aClientOperation replacementString] length];
            NSAssert2(newRange.location >= 0, @"Must be positive. LocalOp: %@, RemoteOp: %@", [aClientOperation description], [aServerOperation description]);
            [aServerOperation setAffectedCharRange:newRange];
            
        } else if ([aServerOperation affectedCharRange].location < [aClientOperation affectedCharRange].location) {
            // server operation range before local operation range
            NSRange newRange = [aClientOperation affectedCharRange];
            newRange.location -= [aServerOperation affectedCharRange].length;
            newRange.location += [[aServerOperation replacementString] length];
            NSAssert2(newRange.location >= 0, @"Must be positive. LocalOp: %@, RemoteOp: %@", [aClientOperation description], [aServerOperation description]);
            [aClientOperation setAffectedCharRange:newRange];
            
        } else {
            if (([aClientOperation affectedCharRange].length == 0) && ([aServerOperation affectedCharRange].length == 0)) {
                NSRange newRange = [aClientOperation affectedCharRange];
                newRange.location += [[aServerOperation replacementString] length];
                [aClientOperation setAffectedCharRange:newRange];
            } else if ([aClientOperation affectedCharRange].length < [aServerOperation affectedCharRange].length) {
                NSRange newRange = [aServerOperation affectedCharRange];
                newRange.location += [[aClientOperation replacementString] length];
                [aServerOperation setAffectedCharRange:newRange];
            } else if ([aClientOperation affectedCharRange].length > [aServerOperation affectedCharRange].length) {
                NSRange newRange = [aClientOperation affectedCharRange];
                newRange.location += [[aServerOperation replacementString] length];
                [aClientOperation setAffectedCharRange:newRange];
            } else {
                NSLog(@"ERROR! This case shouldn't even exist.");
            }
        }
        
    } else {
        // conflicting operations

        NSRange intersectionRange = NSIntersectionRange([aClientOperation affectedCharRange], [aServerOperation affectedCharRange]);

        if ([aServerOperation affectedCharRange].location == [aClientOperation affectedCharRange].location
           && NSMaxRange([aServerOperation affectedCharRange]) == NSMaxRange([aClientOperation affectedCharRange])) {
        
            NSRange newClientRange = [aClientOperation affectedCharRange];
            NSRange newServerRange = [aServerOperation affectedCharRange];
            
            newClientRange.length = 0;
            newClientRange.location += [[aServerOperation replacementString] length];
            
            newServerRange.length = 0;
            
            [aClientOperation setAffectedCharRange:newClientRange];
            [aServerOperation setAffectedCharRange:newServerRange];
        
        } else if ([aServerOperation affectedCharRange].location <= [aClientOperation affectedCharRange].location
           && NSMaxRange([aServerOperation affectedCharRange]) <= NSMaxRange([aClientOperation affectedCharRange])) {
            // server operation location before client operation location
            NSRange newClientRange = [aClientOperation affectedCharRange];
            NSRange newServerRange = [aServerOperation affectedCharRange];

            newServerRange.length -= intersectionRange.length;

            newClientRange.length -= intersectionRange.length;
            newClientRange.location = [aServerOperation affectedCharRange].location + [[aServerOperation replacementString] length];

            [aServerOperation setAffectedCharRange:newServerRange];
		   [aClientOperation setAffectedCharRange:newClientRange];

        } else if ([aServerOperation affectedCharRange].location >= [aClientOperation affectedCharRange].location
                   && NSMaxRange([aServerOperation affectedCharRange]) >= NSMaxRange([aClientOperation affectedCharRange])) {
            // server operation location after client operation location
            NSRange newClientRange = [aClientOperation affectedCharRange];
            NSRange newServerRange = [aServerOperation affectedCharRange];

            newClientRange.length -= intersectionRange.length;

            newServerRange.length -= intersectionRange.length;
            newServerRange.location = [aClientOperation affectedCharRange].location + [[aClientOperation replacementString] length];

            [aServerOperation setAffectedCharRange:newServerRange];
            [aClientOperation setAffectedCharRange:newClientRange];

        } else {
            if ([aServerOperation affectedCharRange].length > [aClientOperation affectedCharRange].length) {
                NSRange newRange = [aServerOperation affectedCharRange];
                newRange.length += [[aClientOperation replacementString] length] - [aClientOperation affectedCharRange].length;
                [aServerOperation setAffectedCharRange:newRange];

                [aClientOperation setAffectedCharRange:NSMakeRange(0, 0)];
                [aClientOperation setReplacementString:@""];
                
            } else if ([aServerOperation affectedCharRange].length < [aClientOperation affectedCharRange].length) {
                NSRange newRange = [aClientOperation affectedCharRange];
                newRange.length += [[aServerOperation replacementString] length] - [aServerOperation affectedCharRange].length;
                [aClientOperation setAffectedCharRange:newRange];

                [aServerOperation setAffectedCharRange:NSMakeRange(0, 0)];
                [aServerOperation setReplacementString:@""];
            } else {
                NSLog(@"ERROR! This case shouldn't even exist.");
            }
        }
    }
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super initWithDictionaryRepresentation:aDictionary];
    if (self) {
        I_affectedCharRange.location = [[aDictionary objectForKey:@"loc"] unsignedIntValue];
        I_affectedCharRange.length = [[aDictionary objectForKey:@"len"] unsignedIntValue];
        [self setReplacementString:[aDictionary objectForKey:@"str"]];
        //NSLog(@"operation: %@", [self description]);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    
    [copy setAffectedCharRange:[self affectedCharRange]];
    [copy setReplacementString:[self replacementString]];
    
    return copy;
}
 
- (void)dealloc {
    [I_replacementString release];
    [super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [[[super dictionaryRepresentation] mutableCopy] autorelease];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_affectedCharRange.location] forKey:@"loc"];
    [dict setObject:[NSNumber numberWithUnsignedInt:I_affectedCharRange.length] forKey:@"len"];
    [dict setObject:[self replacementString] forKey:@"str"];
    return dict;
}

- (BOOL)isEqualTo:(id)anObject {
    return ([super isEqualTo:anObject] && NSEqualRanges(I_affectedCharRange,[anObject affectedCharRange]) && [I_replacementString isEqualToString:[anObject replacementString]]);
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

- (BOOL)isIrrelevant {
    return ((I_affectedCharRange.length == 0) && ([I_replacementString length] == 0));
}

- (BOOL)shouldBeGroupedWithTextOperation:(TextOperation *)priorOperation {
    if (!priorOperation) return NO;
    BOOL result=NO;
    NSRange myRange=[self affectedCharRange];
    NSRange priorRange=[priorOperation affectedCharRange];
    NSString *priorString=[priorOperation replacementString];
    NSString *myString=[self replacementString];
    if (myRange.location == (priorRange.location+[priorString length])) {
        if (myRange.length==0 && priorRange.length==0 && 
            [priorString length]==1 && [myString length] == 1 && 
            ([priorString isWhiteSpace]==[myString isWhiteSpace])) {
            result = YES;
        }
    }
//    NSLog(@"%@ shouldBeGroupedWithTextOperation: %@ ? %@",self,priorOperation,result?@"YES":@"NO");
    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"affectedRange: %@; string: %@; byUser: %@", NSStringFromRange([self affectedCharRange]), [self replacementString], [self userID]];
}

@end
