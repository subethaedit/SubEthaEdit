//  NSDataTCMAdditions.m
//  TCMFoundation
//
//  Created by Dominik Wagner on Wed Apr 28 2004.

#import "NSDataTCMAdditions.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSData (NSDataTCMAdditions)

static char base64EncodingArray[ 64 ] = {
           'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
           'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
           'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
           'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
            };

+ (id)dataWithUUIDString:(NSString *)aUUIDString {
    if (aUUIDString!=nil) {
        CFUUIDRef uuid=CFUUIDCreateFromString(NULL,(CFStringRef)aUUIDString);
        CFUUIDBytes bytes=CFUUIDGetUUIDBytes(uuid);
        CFRelease(uuid);
        return [NSData dataWithBytes:&bytes length:sizeof(CFUUIDBytes)];
    } else {
        return nil;
    }
}

- (NSString *)base64EncodedStringWithLineLength:(int)lineLength {
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

                [result appendString:@"\n"];
            }
        }
    }
	return result;

}

static unsigned long local_preprocessForDecode( const unsigned char *inBytes, unsigned long inBytesLength, unsigned char *outData )
{
	unsigned long		i;
	unsigned char		*outboundData = outData;
	unsigned char		ch;

	for ( i = 0; i < inBytesLength; i++ )
	{
		ch = inBytes[ i ];

		if ((ch >= 'A') && (ch <= 'Z'))
			*outboundData++ = ch - 'A';

		else if ((ch >= 'a') && (ch <= 'z'))
			*outboundData++ = ch - 'a' + 26;

		else if ((ch >= '0') && (ch <= '9'))
			*outboundData++ = ch - '0' + 52;

		else if (ch == '+')
			*outboundData++ = 62;

		else if (ch == '/')
			*outboundData++ = 63;

		else if (ch == '=')
		{	// no op -- put in our stop signal
			*outboundData++ = 255;
			break;
		}
	}

	// How much valid data did we end up with?
	return outboundData - outData;
}

+ (NSData *)dataWithBase64EncodedString:(NSString *)inBase64String
{
    NSMutableData	*mutableData = nil;

    if ( inBase64String && [ inBase64String length ] > 0 )
    {
        unsigned long		ixtext = 0;
        unsigned long		lentext = 0;
        unsigned char		ch = 0;
        unsigned char		inbuf [4] = {}, outbuf [3] = {};
        short				ixinbuf = 0;
        NSData				*base64Data = nil;
		unsigned char		*preprocessed = NULL, *decodedBytes = NULL;
		unsigned long		preprocessedLength = 0, decodedLength = 0;
		short				ctcharsinbuf = 3;
		BOOL				notDone = YES;

        // Convert the string to ASCII data.
        base64Data = [ inBase64String dataUsingEncoding:NSASCIIStringEncoding ];
        lentext = [ base64Data length ];

		preprocessed = malloc( lentext );	// We may have all valid data!

		// Allocate our outbound data, and set it's length.
		// Do this so we can fill it in without allocating memory in small chunks later.
		mutableData = [ NSMutableData dataWithCapacity:( lentext * 3 ) / 4 + 3 ];
		[ mutableData setLength:( lentext * 3 ) / 4 + 3 ];
		decodedBytes = [ mutableData mutableBytes ];

		{
			preprocessedLength = local_preprocessForDecode( [ base64Data bytes ], lentext, preprocessed );
			decodedLength = 0;
			ixtext = 0;
		}

        ixinbuf = 0;

        while ( notDone && ixtext < preprocessedLength )
        {
            ch = preprocessed[ ixtext++ ];

			if ( 255 == ch )	// Hit our stop signal.
			{
				if (ixinbuf == 0)
					break;		// We're done now!

				else if ((ixinbuf == 1) || (ixinbuf == 2))
				{
					ctcharsinbuf = 1;
					ixinbuf = 3;
				}
				else
					ctcharsinbuf = 2;

				notDone = NO;	// We're finished after the outbuf gets copied this time.
			}

			inbuf [ixinbuf++] = ch;

			if ( 4 == ixinbuf )
			{
				ixinbuf = 0;

				outbuf [0] = (inbuf [0] << 2) | ((inbuf [1] & 0x30) >> 4);

				outbuf [1] = ((inbuf [1] & 0x0F) << 4) | ((inbuf [2] & 0x3C) >> 2);

				outbuf [2] = ((inbuf [2] & 0x03) << 6) | inbuf [3];

				memcpy( &decodedBytes[ decodedLength  ], outbuf, ctcharsinbuf );
				decodedLength += ctcharsinbuf;
			}
        } // end while loop on remaining characters

		free( preprocessed );

		// Adjust length down to however many bytes we actually decoded.
		[ mutableData setLength:decodedLength ];
    }

    return mutableData;
}

- (BOOL)startsWithUTF8BOM {
    char utf8_bom[] = {0xef,0xbb,0xbf};
    if ([self length] >=3) {
        char bom_buffer[3];
        [self getBytes:bom_buffer length:3];
        if (bom_buffer[0] == utf8_bom[0] && 
            bom_buffer[1] == utf8_bom[1] && 
            bom_buffer[2] == utf8_bom[2]) {
            return YES;
        }
    }
    return NO;
}

- (id)dataPrefixedWithUTF8BOM {
    static NSData *s_bomData = nil;
    if (!s_bomData) {
        char utf8_bom[] = {0xef,0xbb,0xbf};
        s_bomData = [[NSData alloc] initWithBytes:utf8_bom length:3];
    }
    id result = [[s_bomData mutableCopy] autorelease];
    [result appendData:self];
    return result;
}

- (NSData*)compressedDataWithLevel:(int)aLevel {
    unsigned long length=compressBound([self length]);
    NSMutableData *result = [[[NSMutableData alloc] initWithLength:length] autorelease];
    int zResult = compress2([result mutableBytes],&length,[self bytes],[self length],aLevel);
    if (zResult == Z_OK) {
        [result setLength:length];
        return result;
    } else {
        NSLog(@"%s compression failed %d",__FUNCTION__,zResult);
        return nil;
    }
}

- (NSData*)uncompressedDataOfLength:(unsigned)aLength {
    unsigned long length=aLength;
    NSMutableData *result = [[[NSMutableData alloc] initWithLength:aLength] autorelease];
    int zResult = uncompress([result mutableBytes],&length,[self bytes],[self length]);
    if (zResult == Z_OK) {
        return result;
    } else {
        NSLog(@"%s uncompression failed %d",__FUNCTION__,zResult);
        return nil;
    }
}

- (NSArray *)arrayOfCompressedDataWithLevel:(int)aLevel {
    NSData *compressedData = [self compressedDataWithLevel:aLevel];
    if (compressedData) {
        return [NSArray arrayWithObjects:
                    [NSNumber numberWithUnsignedInt:[self length]],
                    compressedData,
                    nil
                ];
    } else {
        return nil;
    }
}
+ (NSData *)dataWithArrayOfCompressedData:(NSArray *)anArray {
    if ([anArray count]>=2 && 
        [[anArray objectAtIndex:0] isKindOfClass:[NSNumber class]] && 
        [[anArray objectAtIndex:1] isKindOfClass:[NSData class]]) {
        return [[anArray objectAtIndex:1] uncompressedDataOfLength:[[anArray objectAtIndex:0] unsignedIntValue]];
    }
    return nil;
}

- (NSData *)md5Data {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, self.length, result);
    return [NSData dataWithBytes:result length:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)md5String {
	NSData *md5Data = [self md5Data];
	unsigned char *bytes = (unsigned char *)[md5Data bytes];
    return [NSString
			stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			bytes[0], bytes[1],
			bytes[2], bytes[3],
			bytes[4], bytes[5],
			bytes[6], bytes[7],
			bytes[8], bytes[9],
			bytes[10], bytes[11],
			bytes[12], bytes[13],
			bytes[14], bytes[15]
			];
}

@end
