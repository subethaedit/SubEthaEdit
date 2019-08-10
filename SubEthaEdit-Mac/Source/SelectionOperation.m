//  SelectionOperation.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import "SelectionOperation.h"
#import "TextOperation.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SelectionOperation

+ (void)initialize {
	if (self == [SelectionOperation class]) {
	    [TCMMMOperation registerClass:self forOperationType:[self operationID]];
	}
}

+ (SelectionOperation *)selectionOperationWithRange:(NSRange)aRange userID:(NSString *)aUserID {
    SelectionOperation *result = [SelectionOperation new];
    [result setSelectedRange:aRange];
    [result setUserID:aUserID];
    return result;
}

+ (void)transformOperation:(TCMMMOperation *)aClientOperation serverOperation:(TCMMMOperation *)aServerOperation {
    TextOperation *textOperation=nil;
    SelectionOperation *selectionOperation=nil;
    if ([[aClientOperation operationID] isEqualToString:[TextOperation operationID]]) {
        textOperation = (TextOperation *)aClientOperation;
        selectionOperation = (SelectionOperation *)aServerOperation;
    } else {
        textOperation = (TextOperation *)aServerOperation;
        selectionOperation = (SelectionOperation *)aClientOperation;
    }
    
    NSRange selectedRange = [selectionOperation selectedRange];
    if (DisjointRanges([textOperation affectedCharRange], selectedRange)) {
        if ([textOperation affectedCharRange].location < selectedRange.location) {
            selectedRange.location += [[textOperation replacementString] length] - [textOperation affectedCharRange].length;
        }
    } else {
        NSRange intersectionRange = NSIntersectionRange([textOperation affectedCharRange], selectedRange);
        if (intersectionRange.length == [textOperation affectedCharRange].length) {
            selectedRange.length += [[textOperation replacementString] length] - [textOperation affectedCharRange].length;
        } else if (intersectionRange.length == selectedRange.length) {
            selectedRange.location = [textOperation affectedCharRange].location + [[textOperation replacementString] length];
            selectedRange.length = 0;
        } else if (selectedRange.location < [textOperation affectedCharRange].location) {
            selectedRange.length = [textOperation affectedCharRange].location - selectedRange.location;
        } else if (selectedRange.location > [textOperation affectedCharRange].location) {
            selectedRange.location = [textOperation affectedCharRange].location + [[textOperation replacementString] length];
            selectedRange.length -= intersectionRange.length;
        }
    }
    if (!NSEqualRanges(selectedRange,[selectionOperation selectedRange])) {
        [selectionOperation setSelectedRange:selectedRange];
    }
}

+ (NSString *)operationID {
    return @"sel";
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    self = [super initWithDictionaryRepresentation:aDictionary];
    if (self) {
        _selectedRange.location = [[aDictionary objectForKey:@"loc"] unsignedIntValue];
        _selectedRange.length = [[aDictionary objectForKey:@"len"] unsignedIntValue];
        //NSLog(@"operation: %@", [self description]);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];

    [copy setSelectedRange:[self selectedRange]];
    
    return copy;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [[super dictionaryRepresentation] mutableCopy];
    [dict setObject:[NSNumber numberWithUnsignedInt:_selectedRange.location] forKey:@"loc"];
    [dict setObject:[NSNumber numberWithUnsignedInt:_selectedRange.length] forKey:@"len"];
    return dict;
}

- (BOOL)isEqualTo:(id)anObject {
    return ([super isEqualTo:anObject] && NSEqualRanges(_selectedRange,[anObject selectedRange]));
}

- (NSRange)rangeValue {
	return _selectedRange;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"selectedRange: %@; byUser: %@", NSStringFromRange([self selectedRange]), [self userID]];
}

@end
