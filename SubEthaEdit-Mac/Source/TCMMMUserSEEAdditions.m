//  TCMMMUserSEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.

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
            changeColor = [NSColor lightGrayColor];
        }
    }
    return changeColor;
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
    NSData *pngImage=[[self properties] objectForKey:TCMMMUserPropertyKeyImageAsPNGData];
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

- (NSColor *)color {
    NSColor *result = nil;
    NSNumber *hue = [[self properties] objectForKey:@"Hue"];
    if (hue) {
        NSValueTransformer *hueTrans = [NSValueTransformer valueTransformerForName:@"HueToColor"];
        result=[hueTrans transformedValue:hue];
    }
    return result;
}

#pragma mark - Image
- (NSImage *)image {
    NSImage *image = [[self properties] objectForKey:@"Image"];
    if (!image) {
        NSData *pngData = [[self properties] objectForKey:TCMMMUserPropertyKeyImageAsPNGData];
        image = [[NSImage alloc] initWithData:pngData];

        if (!image) { // set default image
			[self setDefaultImage];
			image = [[self properties] objectForKey:@"Image"];
		}
    }
    return image;
}

- (NSData *)imageData {
    NSData *data = [[self properties] objectForKey:TCMMMUserPropertyKeyImageAsPNGData];
    if (!data) {
        NSImage *image = [[self properties] objectForKey:@"Image"];
		
        if (!image) { // set default image
			[self setDefaultImage]; // also sets the image data
			data = [[self properties] objectForKey:TCMMMUserPropertyKeyImageAsPNGData];
			
		} else {
			data = [TCMMMUser imageJPEGDataFromImage:image];
		}
    }
    return data;
}

- (void)setImage:(NSImage *)aImage {
	NSImage *image;
	BOOL hasDefaultImage;

	if (aImage) { // set that image
		hasDefaultImage = NO;
		image = aImage;
				
	} else { // set the default image
		hasDefaultImage = YES;
		image = [self defaultImage];
	}

	NSMutableDictionary *properties = [self properties];

	NSData *pngData = [TCMMMUser imageJPEGDataFromImage:image];
	[properties setObject:pngData forKey:TCMMMUserPropertyKeyImageAsPNGData];
	// this property seems only to be set for non-empty images? may not be set in the future at all but beware of old versions of Coda/SEE

	[properties setObject:@(hasDefaultImage) forKey:@"HasDefaultImage"];
	[properties setObject:image forKey:@"Image"];
	[image setCacheMode:NSImageCacheNever];
}

- (void)setDefaultImage {
	[self setImage:nil];
}

- (BOOL)hasDefaultImage {
	BOOL hasDefaultImage;
	NSNumber *numberHasDefault = [[self properties] objectForKey:@"HasDefaultImage"];
	if (numberHasDefault) {
		hasDefaultImage = [numberHasDefault boolValue];
	} else {
		hasDefaultImage = NO;
	}
	return hasDefaultImage;
}

- (NSImage *)defaultImage {
	NSImage *image = [NSImage unknownUserImageWithSize:NSMakeSize(256.0, 256.0) initials:self.initials];
	return image;
}

#pragma mark - Helper
+ (NSData *)imagePNGDataFromImage:(NSImage *)aImage {
    NSData *data = nil;
    if (aImage) {
        data = [aImage TIFFRepresentation];
        data = [[NSBitmapImageRep imageRepWithData:data] representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    }
    return data;
}

+ (NSData *)imageJPEGDataFromImage:(NSImage *)aImage {
    NSData *data = nil;
    if (aImage) {
        data = [aImage TIFFRepresentation];
        data = [[NSBitmapImageRep imageRepWithData:data] representationUsingType:NSBitmapImageFileTypeJPEG properties:@{NSImageCompressionFactor : @0.80}];
    }
    return data;
}


+ (NSURL *)applicationSupportURLForUserImage {
	NSURL *result;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *possibleURLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
	NSURL *appSupportDir = nil;
	
	if ([possibleURLs count] >= 1) {
		// Use the first directory (if multiple are returned)
		appSupportDir = [possibleURLs objectAtIndex:0];
	}

	NSString *appBundleID = [[NSBundle mainBundle] bundleIdentifier];
	result = [appSupportDir URLByAppendingPathComponent:appBundleID];

	if (![fileManager fileExistsAtPath:[result path] isDirectory:NULL]) {
		[fileManager createDirectoryAtPath:[result path] withIntermediateDirectories:YES attributes:nil error:nil];
	}

	result = [result URLByAppendingPathComponent:@"MeUserImage.png"];
	return result;
}


- (BOOL)writeImageToUrl:(NSURL *)aURL {
	BOOL result = NO;
	NSData *imageData = [TCMMMUser imagePNGDataFromImage:self.image];
	if (imageData) {
		result = [imageData writeToURL:aURL atomically:YES];
	}
	return result;
}

- (BOOL)readImageFromUrl:(NSURL *)aURL {
	BOOL result = NO;
	NSData *imageData = [NSData dataWithContentsOfURL:aURL];
	NSImage *image;
	if (imageData) {
		image = [[NSImage alloc] initWithData:imageData];
	}
	
	if (image) {
		[self setImage:image];
		result = YES;
		
	} else {
		[self setDefaultImage];
	}
	
	return result;
}

- (BOOL)removePersistedUserImage {
	BOOL result = YES;
	NSURL *url = [TCMMMUser applicationSupportURLForUserImage];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	[fileManager removeItemAtURL:url error:&error];
	if (error) {
		result = NO;
	}
	return result;
}

@end
