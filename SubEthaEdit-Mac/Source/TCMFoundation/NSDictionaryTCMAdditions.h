//
//  NSDictionaryTCMAdditions.h
//  TCMFoundation
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (NSDictionaryTCMAdditions)

- (id)objectForLong:(long)aLong;
@end


@interface NSMutableDictionary (NSDictionaryTCMAdditions)
+ (NSMutableDictionary *)caseInsensitiveDictionary;
- (void)removeObjectForLong:(long)aLong;
- (void)setObject:(id)anObject forLong:(long)aLong;

@end

