//
//  NSStringTCMAdditions.m
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSStringTCMAdditions.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <sys/socket.h>

static void convertLineEndingsInString(NSMutableString *string, NSString *newLineEnding)
{
    unsigned newEOLLen;
    unichar newEOLStackBuf[2];
    unichar *newEOLBuf;
    BOOL freeNewEOLBuf = NO;

    unsigned length = [string length];
    unsigned curPos = 0;
    unsigned start, end, contentsEnd;


    newEOLLen = [newLineEnding length];
    if (newEOLLen > 2) {
        newEOLBuf = NSZoneMalloc(NULL, sizeof(unichar) * newEOLLen);
        freeNewEOLBuf = YES;
    } else {
        newEOLBuf = newEOLStackBuf;
    }
    [newLineEnding getCharacters:newEOLBuf];

    NSMutableArray *changes=[[NSMutableArray alloc] init];

    while (curPos < length) {
        [string getLineStart:&start end:&end contentsEnd:&contentsEnd forRange:NSMakeRange(curPos, 0)];
        if (contentsEnd < end) {
            int oldLength = (end - contentsEnd);
            int changeInLength = newEOLLen - oldLength;
            BOOL alreadyNewEOL = YES;
            if (changeInLength == 0) {
                unsigned i;
                for (i = 0; i < newEOLLen; i++) {
                    if ([string characterAtIndex:contentsEnd + i] != newEOLBuf[i]) {
                        alreadyNewEOL = NO;
                        break;
                    }
                }
            } else {
                alreadyNewEOL = NO;
            }
            if (!alreadyNewEOL) {
                [changes addObject:[NSValue valueWithRange:NSMakeRange(contentsEnd, oldLength)]];
            }
        }
        curPos = end;
    }

    int count=[changes count];
    while (--count >= 0) {
        [string replaceCharactersInRange:[[changes objectAtIndex:count] rangeValue] withString:newLineEnding];
        // TODO: put this change also into the undomanager
    }

    [changes release];

    if (freeNewEOLBuf) {
        NSZoneFree(NSZoneFromPointer(newEOLBuf), newEOLBuf);
    }
}

@implementation NSMutableString (NSStringTCMAdditions)

- (void)convertLineEndingsToLineEndingString:(NSString *)aNewLineEndingString {
    convertLineEndingsInString(self,aNewLineEndingString);
}

@end


@implementation NSString (NSStringTCMAdditions) 

+ (NSString *)stringWithUUIDData:(NSData *)aData {
    if (aData!=nil) {
        CFUUIDRef uuid=CFUUIDCreateFromUUIDBytes(NULL,*(CFUUIDBytes *)[aData bytes]);
        NSString *uuidString=(NSString *)CFUUIDCreateString(NULL,uuid);
        CFRelease(uuid);
        return [uuidString autorelease];
    } else {
        return nil;
    }
}


+ (NSString *)stringWithAddressData:(NSData *)aData
{
    struct sockaddr *socketAddress = (struct sockaddr *)[aData bytes];
    
    // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
    // IPv4 Addresses are "255.255.255.255" at max which is smaller
    
    char stringBuffer[40];
    NSString *addressAsString = nil;
    if (socketAddress->sa_family == AF_INET) {
        if (inet_ntop(AF_INET, &((struct in_addr)((struct sockaddr_in *)socketAddress)->sin_addr), stringBuffer, 40)) {
            addressAsString = [NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString = @"IPv4 un-ntopable";
        }
        int port = ((struct sockaddr_in *)socketAddress)->sin_port;
        addressAsString = [addressAsString stringByAppendingFormat:@":%d", port];
    } else if (socketAddress->sa_family == AF_INET6) {
         if (inet_ntop(AF_INET6, &(((struct sockaddr_in6 *)socketAddress)->sin6_addr), stringBuffer, 40)) {
            addressAsString = [NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString = @"IPv6 un-ntopable";
        }
        int port = ((struct sockaddr_in6 *)socketAddress)->sin6_port;
        
        // Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
        addressAsString = [NSString stringWithFormat:@"[%@]:%d", addressAsString, port]; 
    } else {
        addressAsString = @"neither IPv6 nor IPv4";
    }
    
    return [[addressAsString copy] autorelease];
}

+ (NSString *)stringWithData:(NSData *)aData encoding:(NSStringEncoding)aEncoding
{
    return [[[NSString alloc] initWithData:aData encoding:aEncoding] autorelease];
}

+ (NSString *)UUIDString
{
    CFUUIDRef myUUID = CFUUIDCreate(NULL);
    CFStringRef myUUIDString = CFUUIDCreateString(NULL, myUUID);
    [(NSString *)myUUIDString retain];
    CFRelease(myUUIDString);
    CFRelease(myUUID);
    
    return [(NSString *)myUUIDString autorelease];
}

- (BOOL) isValidSerial 
{
	return YES;
/*
    NSArray *splitArray = [self componentsSeparatedByString:@"-"];
    if ([splitArray count]==4) {
        NSString *zero = [splitArray objectAtIndex:0];
        NSString *one = [splitArray objectAtIndex:1];
        NSString *two = [splitArray objectAtIndex:2];
        NSString *tri = [splitArray objectAtIndex:3];
        if (([zero length] == 3) && ([one length] == 4) && ([two length] == 4) && ([tri length] == 4)) {
            long prefix = [zero base36Value];
            // Buchstaben zwirbeln
            long number = [[NSString stringWithFormat:@"%c%c%c%c",
                      [two characterAtIndex:3],
                      [one characterAtIndex:1],
                      [tri characterAtIndex:0],
                      [tri characterAtIndex:2]] base36Value];
            long rndnumber = [[NSString stringWithFormat:@"%c%c%c%c",
                      [one characterAtIndex:0],
                      [tri characterAtIndex:3],
                      [two characterAtIndex:0],
                      [one characterAtIndex:3]] base36Value];
            long chksum = [[NSString stringWithFormat:@"%c%c%c%c",
                      [two characterAtIndex:1],
                      [one characterAtIndex:2],
                      [tri characterAtIndex:1],
                      [two characterAtIndex:2]] base36Value];
            // check for validity
            if (((rndnumber%42) == 0) && (rndnumber >= 42*1111)) {
                if ((((prefix+number+chksum+rndnumber)%4242)==0) && (chksum >= 42*1111)) {
                    return YES;
                }
            }
        }
    }
    return NO;
*/
}

- (long) base36Value 
{
    unichar c;
    int i,p;
    long result = 0;
    NSString *aString = [self uppercaseString];
    
    for (i=[aString length]-1,p=0;i>=0;i--,p++) {
        c = [aString characterAtIndex:i];
        // 65-90:A-Z, 48-57:0-9
        if ((c >= 48) && (c <= 57)) {
            result += (long)(c-48)*pow(36,p);
        }
        if ((c >= 65) && (c <= 90)) {
            result += (long)(c-55)*pow(36,p);
        }
    }
    
    return result;
}

- (BOOL)isWhiteSpace {
    static unichar s_space=0,s_tab,s_cr,s_nl;
    if (s_space==0) {
        s_space=[@" " characterAtIndex:0];
        s_tab=[@"\t" characterAtIndex:0];
        s_cr=[@"\r" characterAtIndex:0];
        s_nl=[@"\n" characterAtIndex:0];
    }

    unsigned int i=0;
    BOOL result=YES;
    for (i=0;i<[self length];i++) {
        unichar character=[self characterAtIndex:i];
        if (character!=s_space &&
            character!=s_tab &&
            character!=s_cr &&
            character!=s_nl) {
            result=NO;
            break;    
        }
    }
    return result;
}

- (unsigned) detabbedLengthForRange:(NSRange)aRange tabWidth:(int)aTabWidth {
    NSRange foundRange=[self rangeOfString:@"\t" options:0 range:aRange];
    if (foundRange.location==NSNotFound) {
        return aRange.length;
    } else {
        unsigned additionalLength=0;
        NSRange searchRange=aRange;
        while (foundRange.location!=NSNotFound) {
            additionalLength+=aTabWidth-((foundRange.location-aRange.location+additionalLength)%aTabWidth+1);
            searchRange.length-=foundRange.location-searchRange.location+1;
            searchRange.location=foundRange.location+1;
            foundRange=[self rangeOfString:@"\t" options:0 range:searchRange];
        }
        return aRange.length+additionalLength;
    }
}

- (BOOL)detabbedLength:(unsigned)aLength fromIndex:(unsigned)aFromIndex 
                length:(unsigned *)rLength upToCharacterIndex:(unsigned *)rIndex
              tabWidth:(int)aTabWidth {
    NSRange searchRange=NSMakeRange(aFromIndex,aLength);
    if (NSMaxRange(searchRange)>[self length]) {
        searchRange.length=[self length]-searchRange.location;
    }
    NSRange foundRange=[self rangeOfString:@"\t" options:0 range:searchRange];
    if (foundRange.location==NSNotFound) {
        *rLength=searchRange.length;
        *rIndex=aFromIndex+searchRange.length;
        return (searchRange.length==aLength);
    } else {
        NSRange lineRange=[self lineRangeForRange:NSMakeRange(aFromIndex,0)];
        *rLength=0;
        while (foundRange.location!=NSNotFound) {
            if (aLength<foundRange.location-searchRange.location) {
                *rLength+=aLength;
                *rIndex=searchRange.location+aLength;
                return YES;
            } else {
                int movement=foundRange.location-searchRange.location;
                *rLength+=movement;
                aLength -=movement;
                int spacesTabTakes=aTabWidth-(aFromIndex-lineRange.location+(*rLength))%aTabWidth;
                if (spacesTabTakes>(int)aLength) {
                    *rIndex=foundRange.location;
                    return NO;
                } else {
                    *rLength+=spacesTabTakes;
                    aLength -=spacesTabTakes;
                    searchRange.location+=movement+1;
                    searchRange.length  -=movement+1;
                }
            }
            foundRange=[self rangeOfString:@"\t" options:0 range:searchRange];
        }
        
        if (aLength<=searchRange.length) {
            *rLength+=aLength;
            *rIndex  =searchRange.location+aLength;
            return YES;
        } else {
            *rLength+=searchRange.length;
            *rIndex  =NSMaxRange(searchRange);
            return NO;
        }
    }
}

@end
