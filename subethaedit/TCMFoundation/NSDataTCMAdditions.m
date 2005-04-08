//
//  NSDataTCMAdditions.m
//  TCMFoundation
//
//  Created by Dominik Wagner on Wed Apr 28 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSDataTCMAdditions.h"


@implementation NSData (NSDataTCMAdditions)

static char base64EncodingArray[ 64 ] = {
           'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
           'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
           'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
           'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
            };

+ dataWithUUIDString:(NSString *)aUUIDString {
    if (aUUIDString!=nil) {
        CFUUIDRef uuid=CFUUIDCreateFromString(NULL,(CFStringRef)aUUIDString);
        CFUUIDBytes bytes=CFUUIDGetUUIDBytes(uuid);
        CFRelease(uuid);
        return [NSData dataWithBytes:&bytes length:sizeof(CFUUIDBytes)];
    } else {
        return nil;
    }
}

- base64EncodedStringWithLineLength:(int)lineLength {
    const unsigned char	*bytes =[self bytes];
    NSMutableString		*result=nil;
    unsigned long		ixtext;
    unsigned long		lentext;
    long				ctremaining;
    unsigned char		inbuf[3],outbuf[4];
    short				i;
    short				charsonline = 0, ctcopy;
    unsigned long		ix;

    ixtext=0;
        
    lentext=[self length];
    result =[NSMutableString stringWithCapacity:lentext];
    [result appendString:@"  "];
    lineLength-=2;

    while (YES) {
        ctremaining = lentext - ixtext;
               
        if (ctremaining <= 0)
            break;

        for (i = 0; i < 3; i++)
        {
            ix = ixtext + i;

            if (ix < lentext)
                inbuf [i] = bytes[ix];
            else
                inbuf [i] = 0;
        } /*for*/

        outbuf [0] = (inbuf [0] & 0xFC) >> 2;
        outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
        outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
        outbuf [3] = inbuf [2] & 0x3F;
        ctcopy = 4;

        switch (ctremaining) {
            case 1: 
                ctcopy = 2; 
                break;
                       
            case 2: 
                ctcopy = 3; 
                break;
        }
        
        for (i = 0; i < ctcopy; i++)
            [result appendFormat:@"%c", base64EncodingArray[outbuf[i]]];

        for (i = ctcopy; i < 4; i++)
            [result appendFormat:@"%c", '='];

        ixtext+=3;
        charsonline+=4;

        if (lineLength > 0) { /*DW 4/8/97 -- 0 means no line breaks*/
            if (charsonline >= lineLength)
            {
                charsonline = 0;

                [result appendString:@"\n  "];
            }
        }
    }
	return result;

}


@end
