//
//  NSColorTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSColorTCMAdditions.h"


@implementation NSColor (NSColorTCMAdditions)

+ (NSColor *) colorForHTMLString:(NSString *) htmlString
{
	NSColor *result = nil;
	
    if ([htmlString hasPrefix:@"#"]) { // Colors have to begin with #
        NSString *aString = [htmlString substringFromIndex:1];
        
        if ([aString length] == 3) { // Short syntax (#fff), double bytes
            NSString *red = [aString substringWithRange:NSMakeRange(0,1)];
            NSString *green = [aString substringWithRange:NSMakeRange(1,1)];
            NSString *blue = [aString substringWithRange:NSMakeRange(2,1)];
            aString = [NSString stringWithFormat:@"%@%@%@%@%@%@",red,red,green,green,blue,blue];
        }
        
        if ([aString length] == 6) { // Seems to be "normal" (#ffffff)
            unsigned int colorCode = 0;
	        unsigned char redByte, greenByte, blueByte;
	
            NSScanner *scanner = [NSScanner scannerWithString:aString];
            [scanner scanHexInt:&colorCode];

            redByte     = (unsigned char) (colorCode >> 16);
            greenByte   = (unsigned char) (colorCode >> 8);
            blueByte    = (unsigned char) (colorCode);
            
            result = [NSColor colorWithCalibratedRed: (float)redByte / 255 
                                               green: (float)greenByte / 255
                                               blue:  (float)blueByte /255
                                               alpha:1.0];
        }
    }
    return result;
}


@end
