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
        [result appendFormat:@"PHOTO;ENCODING=b;TYPE=PNG:\r\n%@\r\n",[pngImage base64EncodedStringWithLineLength:76]];
    }
    [result appendString:@"END:VCARD\r\n"];
    return result;
}

#pragma mark -

- (NSImage *)colorImage
{
    if ([[self properties] objectForKey:@"ColorImage"]) {
        return [[self properties] objectForKey:@"ColorImage"];
    } else {
        NSNumber *hue = [[self properties] objectForKey:@"Hue"];
        if (hue) {
            NSValueTransformer *hueTrans = [NSValueTransformer valueTransformerForName:@"HueToColor"];
            NSColor *color = [hueTrans transformedValue:hue];
            NSRect rect = NSMakeRect(0, 0, 13, 8);
            NSImage *image = [[[NSImage alloc] initWithSize:rect.size] autorelease];
            [image lockFocus];
            [color drawSwatchInRect:rect];
            [[NSColor blackColor] set];
            [NSBezierPath strokeRect:rect];
            [image unlockFocus];
            return image;
        } else {
            return nil;
        }
    }
}

- (NSImage *)image
{
    NSImage *image = [[self properties] objectForKey:@"Image"];
    if (!image) {
        NSData *pngData = [[self properties] objectForKey:@"ImageAsPNG"];
        image = [[[NSImage alloc] initWithData:pngData] autorelease];
        if (!image) {
            image = [[NSImage imageNamed:@"UnknownPerson"] resizedImageWithSize:NSMakeSize(64., 64.)];
            pngData = [image TIFFRepresentation];
            pngData = [[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
            [[self properties] setObject:pngData forKey:@"ImageAsPNG"];
        }   
        [[self properties] setObject:image forKey:@"Image"];
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
