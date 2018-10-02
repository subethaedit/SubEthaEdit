//
//  NSNetServiceTCMAdditions.h
//  TCMFoundation
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSNetService (NSNetServiceTCMAdditions) 
- (NSArray *)TXTRecordArray;
- (NSDictionary *)TXTRecordDictionary;
- (void)setTXTRecordByArray:(NSArray *)anArray;
@end
