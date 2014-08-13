//
//  NSCursorSEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 07.03.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSCursorSEEAdditions.h"
#import <QuartzCore/QuartzCore.h>


@implementation NSCursor (NSCursorSEEAdditions)

+ (NSCursor *)invertedIBeamCursor {
    static NSCursor *s_invertedIBeamCursor;
    if (!s_invertedIBeamCursor) {

		NSURL *cursorURL = [[NSBundle mainBundle] URLForImageResource:@"InvertedIBeam"];
		NSImage *invertedIBeamCursorImage = [[[NSImage alloc] initWithContentsOfURL:cursorURL] autorelease];

/*
		// NSCursor IBeam has 4 Representatios, I tryed to do the same thing, but the big ones are not used when
		// cursor gets zoomed, so for now we dont load it.
		NSURL *bigCursorURL = [[NSBundle mainBundle] URLForImageResource:@"InvertedIBeamBig"];
		NSImage *bigInvertedIBeamCursorImage = [[[NSImage alloc] initWithContentsOfURL:bigCursorURL] autorelease];
		[invertedIBeamCursorImage addRepresentations:[bigInvertedIBeamCursorImage representations]];
		[invertedIBeamCursorImage TIFFRepresentation]; // force loading of representations
*/

		s_invertedIBeamCursor = [[NSCursor alloc] initWithImage:invertedIBeamCursorImage hotSpot:NSMakePoint(4.0, 9.0)];

		//		NSLog(@"%@ - %@", NSStringFromPoint([s_invertedIBeamCursor hotSpot]), s_invertedIBeamCursor.image);
    }
    return s_invertedIBeamCursor;
}

@end
