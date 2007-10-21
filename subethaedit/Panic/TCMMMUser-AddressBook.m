#import "TCMMMUser-AddressBook.h"
//#import "LocaleMacros.h"
#import "NSImageTCMAdditions.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMUserManager.h"

#import <AddressBook/AddressBook.h>


#define LOCAL(a) @"~/Library/Application Support"

@implementation TCMMMUser (AddressBook)


- (void)saveUserImageToApplicationSupport
{
	NSString	*path = [LOCAL(@"ApplicationSupport") stringByExpandingTildeInPath];
	BOOL		isDir = NO;
	
	if ( ! [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] || !isDir )
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		
	path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [self userID]]];
		
	NSData *pngData = [[self properties] objectForKey:@"ImageAsPNG"];
		
	[pngData writeToFile:path atomically:YES];

}


- (void)setUserImage:(NSImage*)inImage writeToSupportFolder:(BOOL)flag
{
	NSImage	*myImage = nil;

	if ( inImage == nil )
		myImage = [NSImage imageNamed:@"genericPerson"];
    else
		myImage = inImage;
	
    // resizing the image to 64x64
	NSSize oldSize =  [myImage size];
	float xScaler = oldSize.width / 64;
	float yScaler = oldSize.height / 64;
	float scaler = fmaxf(xScaler, yScaler);
    
	NSImage *scaledMyImage = [[[NSImage alloc] initWithSize:NSMakeSize(64, 64)] autorelease];

	NSSize newSize;
	
	if ( scaler > 0 )
	{
		newSize.width = floor(oldSize.width / scaler);
		newSize.height = floor(oldSize.height / scaler);
	}
	else
	{
		newSize = oldSize;
	}
	
	[scaledMyImage lockFocus];
    
	NSGraphicsContext		*context = [NSGraphicsContext currentContext];
    NSImageInterpolation	oldInterpolation = [context imageInterpolation];
  
	 [context setImageInterpolation:NSImageInterpolationHigh];
    
	[[NSColor clearColor] set];
    [[NSBezierPath bezierPathWithRect:(NSMakeRect(0.,0.,newSize.width,newSize.height))] fill];
    
    [myImage drawInRect:NSMakeRect((64 - newSize.width)/2,(64 - newSize.height)/2, newSize.width, newSize.height) fromRect:NSMakeRect(0, 0, oldSize.width, oldSize.height) operation:NSCompositeSourceOver fraction:1.0];
	
	[context setImageInterpolation:oldInterpolation];
    
	[scaledMyImage unlockFocus];

	
    NSData	*pngData = [scaledMyImage TIFFRepresentation];
    
	pngData = [[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
    scaledMyImage = [[[NSImage alloc] initWithData:pngData] autorelease];
    
    [[self properties] setObject:scaledMyImage forKey:@"Image"];
    [[self properties] setObject:pngData forKey:@"ImageAsPNG"];
    
    [self prepareImages];
	
	if ( flag )
		[self saveUserImageToApplicationSupport];

	if ( self == [TCMMMUserManager me] )
		[TCMMMUserManager didChangeMe];
}


- (void)updateUserWithAddressCard:(ABPerson*)card
{
	// update TCMMMUser and values from address book
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	NSString		*firstName = [card valueForProperty:kABFirstNameProperty];
	NSString		*lastName  = [card valueForProperty:kABLastNameProperty];            
	ABMultiValue	*emails = [card valueForProperty:kABEmailProperty];
	ABMultiValue	*aims = [card valueForProperty:kABAIMInstantProperty];
	NSImage			*myImage = nil;
	NSString		*myName = nil;
	NSString		*primaryIdentifier = nil;
	NSString		*newValue = nil;
	BOOL			isMe = (self == [TCMMMUserManager me]);
	
	if ( (firstName != nil) && (lastName != nil) )
		myName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
	else if (firstName != nil) 
		myName = firstName;
	else if (lastName != nil) 
		myName = lastName;
	else
		myName = NSFullUserName();
	
	[self setName:myName];
	
	if ( isMe )
		[defaults setObject:myName forKey:MyNamePreferenceKey];
	
	primaryIdentifier = [emails primaryIdentifier];
	
	if (primaryIdentifier) 
	{
		int index = [emails indexForIdentifier:primaryIdentifier];
		newValue = [emails valueAtIndex:index];
		[[self properties] setObject:newValue forKey:@"Email"];

		if ( isMe )
			[defaults setObject:newValue forKey:MyEmailPreferenceKey];
		
	}

	primaryIdentifier = [aims primaryIdentifier];
	if (primaryIdentifier) 
	{
		int index = [aims indexForIdentifier:primaryIdentifier];
		newValue = [aims valueAtIndex:index];
		[[self properties] setObject:newValue forKey:@"AIM"];

		if ( isMe ) 
			[defaults setObject:newValue forKey:MyAIMPreferenceKey];
	}

	NSData  *imageData;
	
	if ( (imageData = [card imageData]) )
	{
		myImage = [[NSImage alloc] initWithData:imageData];
		[myImage setCacheMode:NSImageCacheNever];
	} 

	if (!myImage) 
		myImage = [[NSImage imageNamed:@"genericPerson"] retain];
	
	// resizing the image
	NSImage *scaledMyImage = [myImage resizedImageWithSize:NSMakeSize(64.,64.)];

	NSData *pngData = [scaledMyImage TIFFRepresentation];
	pngData = [[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
	// do this because my resized Images don't behave right on setFlipped:, initWithData ones do!
	scaledMyImage = [[[NSImage alloc] initWithData:pngData] autorelease];

	[[self properties] setObject:scaledMyImage forKey:@"Image"];
	[[self properties] setObject:pngData forKey:@"ImageAsPNG"];

	[myImage release];

	[self prepareImages];

	if ( isMe )
		[TCMMMUserManager didChangeMe];
}

@end
