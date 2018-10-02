//  NSDictionaryTCMAdditions.h
//  TCMFoundation
//
//  Created by Martin Ott on Wed Feb 18 2004.

#import <Foundation/Foundation.h>


@interface NSDictionary (NSDictionaryTCMAdditions)

- (id)objectForLong:(long)aLong;
@end


@interface NSMutableDictionary (NSDictionaryTCMAdditions)
+ (NSMutableDictionary *)caseInsensitiveDictionary;
- (void)removeObjectForLong:(long)aLong;
- (void)setObject:(id)anObject forLong:(long)aLong;

@end

