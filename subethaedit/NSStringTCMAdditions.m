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


@implementation NSString (NSStringTCMAdditions) 

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

@end
