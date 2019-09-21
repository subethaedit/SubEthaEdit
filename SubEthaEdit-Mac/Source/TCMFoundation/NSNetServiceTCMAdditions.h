//  NSNetServiceTCMAdditions.h
//  TCMFoundation
//
//  Created by Dominik Wagner on Fri Feb 27 2004.

#import <Foundation/Foundation.h>

@interface NSNetService (NSNetServiceTCMAdditions) 
- (NSArray *)TXTRecordArray;
- (NSDictionary *)TXTRecordDictionary;
- (void)setTXTRecordByArray:(NSArray *)anArray;
@end
