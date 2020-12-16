//  NSColorTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on Mon Mar 22 2004.

#import "NSColorTCMAdditions.h"

@implementation NSColor (NSColorTCMAdditions)

+ (NSColor *)colorForHTMLString:(NSString *) htmlString
{
	NSColor *result = nil;
    if ([htmlString isEqualToString:@"none"]) return nil;
	
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
    
    if (!result && htmlString) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert setMessageText:NSLocalizedString(@"HTML Color Error",@"HTML Color Error Title")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" is not a valid HTML color. Please specify colors in your syntax defintion either as e.g. \"#fff\" or \"#ffffff\"",@"HTML Color Error Informative Text"),htmlString]];
        [alert addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
        [alert runModal];
        result = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    }
    
    return result;
}

- (NSString *)shortHTMLString {
    NSColor *color=[self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    NSString *result=[NSString stringWithFormat:@"#%01x%01x%01x",
                                  (int)([color   redComponent]*15.+.5),
                                  (int)([color greenComponent]*15.+.5),
                                  (int)([color  blueComponent]*15.+.5)];    
    return result;
}

- (NSString *)HTMLString {
    NSColor *color=[self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    NSString *result=[NSString stringWithFormat:@"#%02x%02x%02x",
                                  (int)([color   redComponent]*255.+.5),
                                  (int)([color greenComponent]*255.+.5),
                                  (int)([color  blueComponent]*255.+.5)];    
    return result;
}

- (BOOL)isDark {
    float brightness=[[self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]] brightnessComponent];
    return (brightness<.5);
}

- (NSColor *)brightnessInvertedColor {
    CGFloat alpha = self.alphaComponent;
    NSColor *color=[self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    NSColor *invertedColor=[NSColor colorWithCalibratedRed:1.0-[color redComponent] green:1.0-[color greenComponent] blue:1.0-[color blueComponent] alpha:1.0];
    return [NSColor colorWithCalibratedHue:[color hueComponent] saturation:[invertedColor saturationComponent] brightness:[invertedColor brightnessComponent] alpha:alpha];
}

- (NSColor *)brightnessInvertedSelectionColor {
    NSColor *color=[self colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    NSColor *invertedColor=[NSColor colorWithCalibratedRed:1.0-[color redComponent] green:1.0-[color greenComponent] blue:1.0-[color blueComponent] alpha:1.0];
    return [NSColor colorWithCalibratedHue:[color hueComponent] saturation:[invertedColor saturationComponent] brightness:MAX([invertedColor brightnessComponent],0.6) alpha:1.0];
}

@end
