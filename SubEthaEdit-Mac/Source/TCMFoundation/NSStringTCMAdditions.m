//  NSStringTCMAdditions.m
//  
//
//  Created by Martin Ott on Tue Feb 17 2004.

#import "NSStringTCMAdditions.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <net/if.h>
#import <arpa/inet.h>
#import <sys/socket.h>

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation NSString (NSStringTCMAdditions) 

+ (NSString *)stringByAddingThousandSeparatorsToNumber:(NSNumber *)aNumber {
    static NSNumberFormatter *mThousandSeparatingNumberFormatter = nil;
    if (!mThousandSeparatingNumberFormatter) {
        mThousandSeparatingNumberFormatter = [NSNumberFormatter new];
        [mThousandSeparatingNumberFormatter setFormat:@"#,###,###,###,###,###,###,###,###,##0"];
    }
    return [mThousandSeparatingNumberFormatter stringFromNumber:aNumber];
}


+ (NSString *)stringWithUUIDData:(NSData *)aData {
    static NSMutableDictionary *dictionary = nil;
    if (!dictionary) dictionary = [NSMutableDictionary new];
    if (aData!=nil && [aData length]>= sizeof(CFUUIDBytes)) {
        CFUUIDRef uuid=CFUUIDCreateFromUUIDBytes(NULL,*(CFUUIDBytes *)[aData bytes]);
        NSString *uuidString=(NSString *)CFBridgingRelease(CFUUIDCreateString(NULL,uuid));
        CFRelease(uuid);
        NSString *result = [dictionary objectForKey:uuidString];
        if (uuidString) {
            if (!result) {
                [dictionary setObject:uuidString forKey:uuidString];
                result = uuidString;
            }
        } else {
            NSLog(@"%s %@ was nil",__FUNCTION__,aData);
        }
        return result;
    } else {
        return nil;
    }
}

+ (NSString *)stringWithData:(NSData *)aData encoding:(NSStringEncoding)aEncoding
{
    return [[NSString alloc] initWithData:aData encoding:aEncoding];
}

+ (NSString *)UUIDString
{
    CFUUIDRef myUUID = CFUUIDCreate(NULL);
    CFStringRef myUUIDString = CFUUIDCreateString(NULL, myUUID);
    CFRelease(myUUID);
    
    return (NSString *)CFBridgingRelease(myUUIDString);
}

+ (NSString *)stringWithAddressData:(NSData *)aData cyrusSASLCompatible:(BOOL)cyrusSASLCompatible
{
    struct sockaddr *socketAddress = (struct sockaddr *)[aData bytes];
    
    // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
    // IPv4 Addresses are "255.255.255.255" at max which is smaller
    
    char stringBuffer[MAX(INET6_ADDRSTRLEN,INET_ADDRSTRLEN)];
    NSString *addressAsString = nil;
    if (socketAddress->sa_family == AF_INET) {
        if (inet_ntop(AF_INET, &(((struct sockaddr_in *)socketAddress)->sin_addr), stringBuffer, INET_ADDRSTRLEN)) {
            addressAsString = [NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString = @"IPv4 un-ntopable";
        }
        int port = ntohs(((struct sockaddr_in *)socketAddress)->sin_port);
        if (cyrusSASLCompatible) {
            addressAsString = [addressAsString stringByAppendingFormat:@";%d", port];
        } else {
            addressAsString = [addressAsString stringByAppendingFormat:@":%d", port];
        }
    } else if (socketAddress->sa_family == AF_INET6) {
         if (inet_ntop(AF_INET6, &(((struct sockaddr_in6 *)socketAddress)->sin6_addr), stringBuffer, INET6_ADDRSTRLEN)) {
            addressAsString = [NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString = @"IPv6 un-ntopable";
        }
        int port = ntohs(((struct sockaddr_in6 *)socketAddress)->sin6_port);
        
        // Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
        if (cyrusSASLCompatible) {
            addressAsString = [NSString stringWithFormat:@"%@;%d", addressAsString, port];
        } else {
            char interfaceName[IF_NAMESIZE];
            if ([addressAsString hasPrefix:@"fe80"] && if_indextoname(((struct sockaddr_in6 *)socketAddress)->sin6_scope_id,interfaceName)) {
                NSString *zoneID = [NSString stringWithUTF8String:interfaceName];
                addressAsString = [NSString stringWithFormat:@"[%@%%%@]:%d", addressAsString, zoneID, port];
            } else {
                addressAsString = [NSString stringWithFormat:@"[%@]:%d", addressAsString, port];
            }
        }
    } else {
        addressAsString = @"neither IPv6 nor IPv4";
    }
    
    return [addressAsString copy];
}

+ (NSString *)stringWithAddressData:(NSData *)aData
{
    return [NSString stringWithAddressData:aData cyrusSASLCompatible:NO];
}

- (NSData *)UTF8DataWithMaximumLength:(unsigned)aLength {
    NSData *result=[self dataUsingEncoding:NSUTF8StringEncoding];
    if ([result length]>aLength) {
        // truncate at a valid UTF8 boundary
        // see RFC http://www.ietf.org/rfc/rfc3629.txt
        unsigned char *bytes=(unsigned char *)[result bytes];
        unsigned char *end=bytes+aLength;
        // 0x80 = 1000 0000
        // 0x40 = 0100 0000
        // all characters not matching 10xx xxxx are non boundaries
        while ((*end & 0x80) && !(*end & 0x40) && end > bytes) {
            end--;
        }
        result = [result subdataWithRange:NSMakeRange(0,end - bytes)];
    }
    return result;
}

@end


@implementation NSMutableAttributedString (NSMutableAttributedStringTCMAdditions) 

- (void)appendString:(NSString *)aString {
    [self replaceCharactersInRange:NSMakeRange([self length],0) withString:aString];
}

@end
