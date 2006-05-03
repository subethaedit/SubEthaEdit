//
//  NSRangeSpecifierTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on 4/25/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSRangeSpecifierTCMAdditions.h"
#import "TextStorage.h"


@implementation NSRangeSpecifier (NSRangeSpecifierTCMAdditions)

- (id)objectsByEvaluatingSpecifier
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"%@", [self description]);
    NSLog(@"key: %@", [self key]);
    
    //return @"foo";
    return [super objectsByEvaluatingSpecifier];
}

- (id)objectsByEvaluatingWithContainers:(id)containers
{
    NSLog(@"%s", __FUNCTION__);
    if ([[self key] isEqual:@"characters"]) {
        int numRefs;
        int *indices = [self indicesOfObjectsByEvaluatingWithContainer:containers count:&numRefs];
        if (numRefs > 0) {
            NSRange range = NSMakeRange(indices[0], numRefs);
            NSLog(@"range: %@", NSStringFromRange(range));
            TextStorage *subTextStorage = [[TextStorage alloc] initWithContainerTextStorage:containers range:range];
            return [subTextStorage autorelease];
        }
    }
    
    return [super objectsByEvaluatingWithContainers:containers];
}

@end
