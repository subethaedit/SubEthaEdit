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


NSData *TCM_BencodedObject(id aObject) {
    NSMutableData *result=[NSMutableData data];
    
    if ([aObject isKindOfClass:[NSString class]]) {
        NSData *data=[aObject dataUsingEncoding:NSUTF8StringEncoding];
        [result appendData:[[NSString stringWithFormat:@"%d:",[data length]] dataUsingEncoding:NSUTF8StringEncoding]];
        [result appendData:data];
    } else if ([aObject isKindOfClass:[NSData class]]) {
        [result appendData:[[NSString stringWithFormat:@"%d.",[(NSData *)aObject length]] dataUsingEncoding:NSUTF8StringEncoding]];
        [result appendData:aObject];
    } else if ([aObject isKindOfClass:[NSDictionary class]]) {
        [result appendBytes:"d" length:1];
        NSEnumerator *keys=[aObject keyEnumerator];
        id key=nil;
        while ((key=[keys nextObject])) {
            [result appendData:TCM_BencodedObject(key)];
            [result appendData:TCM_BencodedObject([aObject objectForKey:key])];
        }
        [result appendBytes:"e" length:1];
    } else if ([aObject isKindOfClass:[NSArray class]]) {
        [result appendBytes:"l" length:1];
        NSEnumerator *objects=[aObject objectEnumerator];
        id object=nil;
        while ((object=[objects nextObject])) {
            [result appendData:TCM_BencodedObject(object)];
        }
        [result appendBytes:"e" length:1];
    } else if ([aObject isKindOfClass:[NSNumber class]]) {
        long long number=[aObject longLongValue];
        NSData *longLongData=[[NSString stringWithFormat:@"i%qie",number] dataUsingEncoding:NSUTF8StringEncoding];
        [result appendData:longLongData];
    }
    
    return result;
}

id TCM_BdecodedObjectWithData(NSData *data) {
    unsigned position=0;
    return TCM_BdecodedObject((uint8_t *)[data bytes],&position,[data length]);
}

id TCM_BdecodedObject(uint8_t *aBytes, unsigned *aPosition, unsigned aLength) {
    if (aLength==0) return nil;
    id result=nil;
    if (aBytes[*aPosition]=='d') {
        result=[NSMutableDictionary dictionary];
        (*aPosition)++;
        while (YES) {
            if (aBytes[*aPosition]=='e') {
                (*aPosition)++;
                break;
            } else {
                id key=TCM_BdecodedObject(aBytes,aPosition,aLength);
                id value=TCM_BdecodedObject(aBytes,aPosition,aLength);
                if (key && value) {
                    [result setObject:value forKey:key];
                } else { 
                    return nil;
                }
            }
        }
    } else if (aBytes[*aPosition]=='l') {
        result=[NSMutableArray array];
        (*aPosition)++;
        while (YES) {
            if (aBytes[*aPosition]=='e') {
                (*aPosition)++;
                break;
            } else {
                id value=TCM_BdecodedObject(aBytes,aPosition,aLength);
                if (value) {
                    [result addObject:value];
                } else {
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
            result=[[[NSString alloc] initWithBytes:&aBytes[*aPosition] length:length encoding:NSUTF8StringEncoding] autorelease];
            *aPosition=(*aPosition)+length;
        } else if (aBytes[*aPosition]=='.') {
            (*aPosition)++;
            result=[[[NSData alloc] initWithBytes:&aBytes[*aPosition] length:length] autorelease];
            *aPosition=(*aPosition)+length;
        }
    } else if (aBytes[*aPosition]=='i') {
        (*aPosition)++;
        long long number=0;
        while (*aPosition<aLength && aBytes[*aPosition]>='0' && aBytes[*aPosition]<='9') {
            number=number*10+aBytes[*aPosition]-'0';
            (*aPosition)++;
        }
        if (aBytes[*aPosition]=='e') {
            result=[NSNumber numberWithLongLong:number];
            (*aPosition)++;
        } else {
            result=nil;
        }
    }
    return result;
}


