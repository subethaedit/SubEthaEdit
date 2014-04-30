//
//  TCMMMUserSEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMUserSEEAdditions.h"
#import "TCMMMUser.h"
#import "TCMBencodingUtilities.h"

#import "NSImageTCMAdditions.h"
#import "PreferenceKeys.h"

@implementation TCMMMUser (TCMMMUserSEEAdditions) 

- (NSColor *)changeColor {
    NSColor *changeColor = [[self properties] objectForKey:@"ChangeColor"];
    if (!changeColor) {
        NSNumber *hue = [[self properties] objectForKey:@"Hue"];
        if (hue) {
            NSValueTransformer *hueTrans = [NSValueTransformer valueTransformerForName:@"HueToColor"];
            changeColor = [hueTrans transformedValue:hue];
        } else {
            changeColor = [NSColor redColor];
        }
    }
    return changeColor;
}

- (NSColor *)changeColorDesaturated
{
	return [NSColor colorWithCalibratedHue:self.changeColor.hueComponent saturation:0.85 brightness:1.0 alpha:1.0];
}

- (NSColor *)changeHighlightColorWithWhiteBackground
{
	return [self changeHighlightColorForBackgroundColor:[NSColor whiteColor]];
}

- (NSColor *)changeHighlightColorForBackgroundColor:(NSColor *)backgroundColor
{
	NSColor *changeColor = self.changeColor;
	NSColor *highlightColor = changeColor;
	if (backgroundColor) {
		CGFloat saturation = [[NSUserDefaults standardUserDefaults] doubleForKey:ChangesSaturationPreferenceKey] / 100.0;
		NSColor *changeColor = self.changeColor;

		highlightColor = [backgroundColor blendedColorWithFraction:saturation ofColor:changeColor];
	}
	return highlightColor;
}

- (NSString *)vcfRepresentation {
    NSMutableString *result=[NSMutableString stringWithString:@"BEGIN:VCARD\r\nVERSION:3.0\r\n"];
    //[result appendFormat:@"N:%@;;;;\r\n", [self name]];
    [result appendFormat:@"FN:%@\r\n", [self name]];
    NSString *email=[[self properties] objectForKey:@"Email"];
    if (email && [email length]>0) {
        [result appendFormat:@"EMAIL;type=INTERNET;type=WORK;type=pref:%@\r\n",email];
    }
    NSString *aim=[[self properties] objectForKey:@"AIM"];
    if (aim && [aim length]>0) {
        [result appendFormat:@"X-AIM;type=HOME;type=pref:%@\r\n",aim];
    }
    NSData *pngImage=[[self properties] objectForKey:@"ImageAsPNG"];
    if (pngImage && [pngImage length]>0) {        
        NSMutableString *vcfCompliantString = [NSMutableString string];
        NSString *encodedString = [pngImage base64EncodedStringWithLineLength:74];
        NSArray *lines = [encodedString componentsSeparatedByString:@"\n"];
        unsigned i;
        for (i = 0; i < [lines count]; i++) {
            NSString *line = [lines objectAtIndex:i];
            [vcfCompliantString appendString:@"  "];
            [vcfCompliantString appendString:line];
            if (i != ([lines count] - 1)) [vcfCompliantString appendString:@"\n"];
        }
        [result appendFormat:@"PHOTO;ENCODING=b;TYPE=PNG:\r\n%@\r\n",vcfCompliantString];
    }
    [result appendString:@"END:VCARD\r\n"];
    return result;
}

- (NSString *)initials
{
	return self.name.stringWithInitials;
}

#pragma mark -

- (void)recacheImages {
    NSMutableDictionary *properties = [self properties];
    [properties removeObjectsForKeys:@[@"Image", @"Image32", @"Image48", @"Image16", @"Image32Dimmed", @"ColorImage", @"ColorImageBrightLine"]];
}

- (NSColor *)color {
    NSColor *result = nil;
    NSNumber *hue = [[self properties] objectForKey:@"Hue"];
    if (hue) {
        NSValueTransformer *hueTrans = [NSValueTransformer valueTransformerForName:@"HueToColor"];
        result=[hueTrans transformedValue:hue];
    }
    return result;
}

- (NSImage *)colorImageWithLineOfColor:(NSColor *)aColor {
    NSNumber *hue = [[self properties] objectForKey:@"Hue"];
    if (hue) {
        NSValueTransformer *hueTrans = [NSValueTransformer valueTransformerForName:@"HueToColor"];
        NSColor *color = [hueTrans transformedValue:hue];
        NSRect rect = NSMakeRect(0, 0, 13, 8);

		NSImage *image = [NSImage imageWithSize:rect.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
			[color drawSwatchInRect:dstRect];
			[aColor set];
			[NSBezierPath strokeRect:dstRect];
			return YES;
		}];
        return image;
    } else {
        return nil;
    }
}

- (NSImage *)colorImage {
    if (![[self properties] objectForKey:@"ColorImage"]) {
        NSImage *image = [self colorImageWithLineOfColor:[[NSColor blackColor] colorWithAlphaComponent:0.7]];
        if (image) {
            [[self properties] setObject:image forKey:@"ColorImage"];
        }
    }
    return [[self properties] objectForKey:@"ColorImage"];
}

- (NSImage *)colorImageWithBrightLine {
    if (![[self properties] objectForKey:@"ColorImageBrightLine"]) {
        NSImage *image = [self colorImageWithLineOfColor:[[NSColor whiteColor] colorWithAlphaComponent:0.7]];
        if (image) {
            [[self properties] setObject:image forKey:@"ColorImageBrightLine"];
        }
    }
    return [[self properties] objectForKey:@"ColorImageBrightLine"];
}

- (NSImage *)image
{
    NSImage *image = [[self properties] objectForKey:@"Image"];
    if (!image) {
        NSData *pngData = [[self properties] objectForKey:@"ImageAsPNG"];
        image = [[[NSImage alloc] initWithData:pngData] autorelease];

        if (!image) {
			image = [NSImage unknownUserImageWithSize:NSMakeSize(256.0, 256.0) initials:self.initials];

            pngData = [image TIFFRepresentation];
            pngData = [[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
            [[self properties] setObject:pngData forKey:@"ImageAsPNG"];
		}

		if (image) {
			[[self properties] setObject:image forKey:@"Image"];
			[image setCacheMode:NSImageCacheNever];
		}
    }
    return image;
}

- (NSImage *)image48
{
    NSImage *image = [[self properties] objectForKey:@"Image48"];
    if (!image) {
        image = [self image];
        if (image) {
            image = [image resizedImageWithSize:NSMakeSize(48.0, 48.0)];
            [[self properties] setObject:image forKey:@"Image48"];
        }
    }
    return image;
}

- (NSImage *)image32
{
    NSImage *image = [[self properties] objectForKey:@"Image32"];
    if (!image) {
        image = [self image];
        if (image) {
            image = [image resizedImageWithSize:NSMakeSize(32.0, 32.0)];
            [[self properties] setObject:image forKey:@"Image32"];
        }
    }
    return image;
}

- (NSImage *)image16
{
    NSImage *image = [[self properties] objectForKey:@"Image16"];
    if (!image) {
        image = [self image];
        if (image) {
            image = [image resizedImageWithSize:NSMakeSize(16.0, 16.0)];
            [[self properties] setObject:image forKey:@"Image16"];
        }
    }
    return image;
}

- (NSImage *)image32Dimmed
{
    NSImage *image = [[self properties] objectForKey:@"Image32Dimmed"];
    if (!image) {
        image = [self image32];
        if (image) {
            image = [image dimmedImage];
            [[self properties] setObject:image forKey:@"Image32Dimmed"];
        }
    }
    return image;
}

    
@end
