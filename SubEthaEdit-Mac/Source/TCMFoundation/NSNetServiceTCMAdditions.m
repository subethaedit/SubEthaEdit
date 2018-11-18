//  NSNetServiceTCMAdditions.m
//  TCMFoundation
//
//  Created by Dominik Wagner on Fri Feb 27 2004.

#import "NSNetServiceTCMAdditions.h"
#import "NSStringTCMAdditions.h"

@implementation NSNetService (NSNetServiceTCMAdditions)
- (NSArray *)TXTRecordArray {
	NSMutableArray *result   =[NSMutableArray array];
	NSData         *TXTRecord=[self TXTRecordData];
	DEBUGLOG(@"RendezvousLogDomain", AllLogLevel,@"%@ - Data: %@",
			 [[[NSString alloc] 
				initWithData:TXTRecord 
				encoding:NSMacOSRomanStringEncoding] autorelease],
			 TXTRecord);
			 
	unsigned char *bytes=(unsigned char *)[TXTRecord bytes];
	unsigned char *bytesEnd=bytes + [TXTRecord length];
	while (bytes<bytesEnd) {
		unsigned char length=*bytes++;
		if (bytes+length > bytesEnd) {
			length = bytesEnd-bytes;
		}
		if (length>0) {
			NSString *string=[[NSString alloc] 
								initWithBytes:bytes 
									   length:(NSUInteger)length 
									 encoding:NSUTF8StringEncoding];
			if (string) {
				[result addObject:string];
				[string release];
			}
		}
		bytes+=length;
	}
	DEBUGLOG(@"RendezvousLogDomain", AllLogLevel,@"Array: %@",result);
	return result;
}

- (NSDictionary *)TXTRecordDictionary {
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSArray *pairsArray=[self TXTRecordArray];
    NSString *pair;
    for (pair in pairsArray) {
        NSRange foundRange=[pair rangeOfString:@"="];
        if (foundRange.location!=NSNotFound) {
            NSString *key = [[pair substringToIndex:foundRange.location] lowercaseString];
            NSString *value=[pair substringFromIndex:NSMaxRange(foundRange)];
            [result setObject:value forKey:key];
        } else {
            [result setObject:[NSNull null] forKey:pair];
        }
    }
    return result;
}

#define TXTRECORD_MAX_BYTE_LENGTH              0xffff
#define TXTRECORD_MAX_RECOMMENDEND_BYTE_LENTH  1300
// see http://files.dns-sd.org/draft-cheshire-dnsext-dns-sd.txt

- (void)setTXTRecordByArray:(NSArray *)anArray {
    DEBUGLOG(@"RendezvousLogDomain",AllLogLevel,@"should set array: \n%@",anArray);
	NSMutableData *data=[NSMutableData data];
	NSString *string=nil;
	for (string in anArray) {
		NSData *stringData=[string UTF8DataWithMaximumLength:255];
		if ([stringData length]>0) {
			unsigned char length=(unsigned char)[stringData length];
			[data appendBytes:&length length:1];
			[data appendData:stringData];
		}
	}
	DEBUGLOG(@"RendezvousLogDomain",AllLogLevel,@"converted array: \n%@",[NSNetService dictionaryFromTXTRecordData:data]);

	[self setTXTRecordData:data];
}

@end
