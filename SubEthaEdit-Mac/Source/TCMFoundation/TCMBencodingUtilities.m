//
//  TCMBencodingUtilities.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

/* Bencoding is done as follows:

Strings are length-prefixed base ten followed by a colon and the string. For example 4:spam corresponds to 'spam'.

Integers are represented by an 'i' followed by the number in base 10 followed by an 'e'. For example i3e corresponds to 3 and i-3e corresponds to -3. Integers have no size limitation. i-0e is invalid. All encodings with a leading zero, such as i03e, are invalid, other than i0e, which of course corresponds to 0.

Lists are encoded as an 'l' followed by their elements (also bencoded) followed by an 'e'. For example l4:spam4:eggse corresponds to ['spam', 'eggs'].

Dictionaries are encoded as a 'd' followed by a list of alternating keys and their corresponding values followed by an 'e'. For example, d3:cow3:moo4:spam4:eggse corresponds to {'cow': 'moo', 'spam': 'eggs'} and d4:spaml1:a1:bee corresponds to {'spam': ['a', 'b']} . Keys must be strings and appear in sorted order (sorted as raw strings, not alphanumerics).
*/

#import "TCMBencodingUtilities.h"

@implementation TCMMutableBencodedData
- (id)initWithObject:(id)anObject {
    return [self initWithData:TCM_BencodedObject(anObject)];
}

- (id)initWithData:(NSData *)aData {
    if ((self=[super init])) {
        if (!aData) { aData = [NSData data]; };
        I_mutableData = [aData mutableCopy];
    }
    return self;
}

- (void)dealloc {
    [I_mutableData release];
    [super dealloc];
}

- (NSData*)data {
    return (NSData *)I_mutableData;
}

- (void)appendObjectToBencodedArray:(id)anObject {
    NSData *objectData = TCM_BencodedObject(anObject);
    if (objectData) {
        [I_mutableData replaceBytesInRange:NSMakeRange([I_mutableData length]-1,0) withBytes:[objectData bytes] length:[objectData length]];
    }
}

- (void)appendObjectsFromArrayToBencodedArray:(NSArray *)anArray {
    NSData *objectData = TCM_BencodedObject(anArray);
    if (objectData) {
        [I_mutableData replaceBytesInRange:NSMakeRange([I_mutableData length]-1,0) withBytes:[objectData bytes]+1 length:[objectData length]-2];
    }
}

- (id)mutableBencodedDataByAppendingObjectsFromArrayToBencodedArray:(NSArray *)anArray {
    TCMMutableBencodedData *result = [[[TCMMutableBencodedData alloc] initWithData:[self data]] autorelease];
    [result appendObjectsFromArrayToBencodedArray:anArray];
    return result;
}

- (id)decodedObject {
    return TCM_BdecodedObjectWithData([self data]);
}

@end

#define ConversionBufferLength 4096

CFIndex TCM_AppendStringToMutableData(NSString *inString, NSMutableData *inData) {
	UInt8 buffer[ConversionBufferLength];
	CFIndex maxBufLen = ConversionBufferLength;
	CFIndex usedBufLen = 0;
	CFIndex totalBufLen = 0;
	CFRange rangeToConvert = CFRangeMake(0,[inString length]);
	while (rangeToConvert.length > 0) {
		CFIndex convertedCharacters = CFStringGetBytes(
			(CFStringRef)inString,
			rangeToConvert,
			kCFStringEncodingUTF8,
			0,
			true,
			buffer,
			maxBufLen,
			&usedBufLen
		);
		if (convertedCharacters == 0) {
			// something went totally wrong here
			NSLog(@"%s failed to convert characters",__FUNCTION__);
			return 0;
		} else {
			rangeToConvert.location += convertedCharacters;
			rangeToConvert.length   -= convertedCharacters;
			[inData appendBytes:buffer length:usedBufLen];
			totalBufLen += usedBufLen;
		}
	}
	return totalBufLen;
}

void TCM_AppendBencodedObjectToData(id inObject, NSMutableData *inData) {
	NSMutableData *result = inData;
    if ([inObject isKindOfClass:[TCMMutableBencodedData class]]) {
        [result appendData:[(TCMMutableBencodedData *)inObject data]];
    } else if ([inObject isKindOfClass:[NSString class]]) {
        CFIndex stringByteLength = TCM_AppendStringToMutableData((NSString *)inObject,result);
		NSString *prefixString = [[NSString alloc] initWithFormat:@"%ld:",stringByteLength];
        NSMutableData *prefixData = [[NSMutableData alloc] init];
        TCM_AppendStringToMutableData(prefixString,prefixData);
        [result replaceBytesInRange:NSMakeRange([result length] - stringByteLength,0) withBytes:[prefixData bytes] length:[prefixData length]];
        [prefixData release];
        [prefixString release];
    } else if ([inObject isKindOfClass:[NSData class]]) {
		NSString *prefixString = [[NSString alloc] initWithFormat:@"%lu.",(unsigned long)[(NSData *)inObject length]];
        TCM_AppendStringToMutableData(prefixString,result);
        [prefixString release];
        [result appendData:inObject];
    } else if ([inObject isKindOfClass:[NSDictionary class]]) {
        [result appendBytes:"d" length:1];
        NSEnumerator *keys=[inObject keyEnumerator];
        id key=nil;
        while ((key=[keys nextObject])) {
        	TCM_AppendBencodedObjectToData(key,result);
        	TCM_AppendBencodedObjectToData([inObject objectForKey:key],result);
        }
        [result appendBytes:"e" length:1];
    } else if ([inObject isKindOfClass:[NSArray class]]) {
        [result appendBytes:"l" length:1];
        NSEnumerator *objects=[inObject objectEnumerator];
        id object=nil;
        while ((object=[objects nextObject])) {
			TCM_AppendBencodedObjectToData(object,result);
        }
        [result appendBytes:"e" length:1];
    } else if ([inObject isKindOfClass:[NSNumber class]]) {
        long long number=[inObject longLongValue];
		NSString *string = [[NSString alloc] initWithFormat:@"i%qie",number];
        TCM_AppendStringToMutableData(string,result);
        [string release];
    }
}

NSData *TCM_BencodedObject(id aObject) {
    NSMutableData *result=[NSMutableData data];
    TCM_AppendBencodedObjectToData(aObject,result);
    return result;
}

// returns an autoreleased object
id TCM_BdecodedObjectWithData(NSData *data) {
    unsigned position=0;
    return [TCM_CopyBdecodedObject((uint8_t *)[data bytes],&position,[data length]) autorelease];
}


// returns a retained object
id TCM_CopyBdecodedObject(uint8_t *aBytes, unsigned *aPosition, unsigned aLength) {
    if (aLength==0) return nil;
    id result = nil;
    if (aBytes[*aPosition]=='d') {
		static NSMutableDictionary *S_bencodingDictionaryKeysDictionary = nil; // this is for not creating strings multiple times on load and decode
		if (!S_bencodingDictionaryKeysDictionary) { S_bencodingDictionaryKeysDictionary = [NSMutableDictionary new]; }

        result=[NSMutableDictionary new];
        (*aPosition)++;
        while (YES) {
            if (aBytes[*aPosition]=='e') {
                (*aPosition)++;
                break;
            } else {
				id key=TCM_CopyBdecodedObject(aBytes,aPosition,aLength);
				if (key) {
					id value=TCM_CopyBdecodedObject(aBytes,aPosition,aLength);
					if (value) {
						NSString *decodedKey = [S_bencodingDictionaryKeysDictionary objectForKey:key];
						if (! decodedKey) {
							decodedKey = [[key retain] autorelease];
							[S_bencodingDictionaryKeysDictionary setObject:decodedKey forKey:key];
						}
						[result setObject:value forKey:decodedKey];
						[value release];
						value = nil;
					}
					[key release];
					key = nil;
                } else {
					[result release];
                    return nil;
                }
            }
        }
    } else if (aBytes[*aPosition]=='l') {
        result=[NSMutableArray new];
        (*aPosition)++;
        while (YES) {
            if (aBytes[*aPosition]=='e') {
                (*aPosition)++;
                break;
            } else {
                id value=TCM_CopyBdecodedObject(aBytes,aPosition,aLength);
                if (value) {
                    [result addObject:value];
					[value release];
                } else {
					[result release];
                    return nil;
                }
            }
        }
    } else if (aBytes[*aPosition]>='0' && aBytes[*aPosition]<='9') {
        unsigned length=0;
        while (*aPosition<aLength && aBytes[*aPosition]>='0' && aBytes[*aPosition]<='9') {
            length=length*10+aBytes[*aPosition]-'0';
            (*aPosition)++;
        }
        if (aBytes[*aPosition]==':') {
            (*aPosition)++;
            result=[[NSString alloc] initWithBytes:&aBytes[*aPosition] length:length encoding:NSUTF8StringEncoding];
            *aPosition=(*aPosition)+length;
        } else if (aBytes[*aPosition]=='.') {
            (*aPosition)++;
            result=[[NSData alloc] initWithBytes:&aBytes[*aPosition] length:length];
            *aPosition=(*aPosition)+length;
        }
    } else if (aBytes[*aPosition]=='i') {
        (*aPosition)++;
        long long signum=aBytes[*aPosition]=='-'?-1:1;
        if (signum < 0) (*aPosition)++;
        long long number=0;
        while (*aPosition<aLength && aBytes[*aPosition]>='0' && aBytes[*aPosition]<='9') {
            number=number*10+aBytes[*aPosition]-'0';
            (*aPosition)++;
        }
        if (aBytes[*aPosition]=='e') {
            result=[[NSNumber alloc] initWithLongLong:number*signum];
            (*aPosition)++;
        }
    }
    return result;
}


