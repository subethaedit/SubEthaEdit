//
//  NSDictionaryTCMAdditions.h
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (NSDictionaryTCMAdditions)
-(id)objectForLong:(long)aLong;
@end

@interface NSMutableDictionary (NSDictionaryTCMAdditions)
-(void)setObject:(id)aObject forLong:(long)aLong;
@end

