//
//  PrecedenceRolloverButton.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 01.10.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "PrecedenceRolloverButton.h"


@implementation PrecedenceRolloverButton

- (void)configure
{
    mouseIsIn = NO;	
	trackingTag = 0;
	TCM_altImage = [[NSImage imageNamed:@"Precedence_RemoveRollover"] retain];
}

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		[self configure];
    }
    
	return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) 
	{
		[self configure];
    }
	
    return self;
}

- (void)dealloc
{
	[TCM_altImage release];	
	[super dealloc];
}

- (void)mouseEntered:(NSEvent*)anEvent
{
	if ( [self isEnabled] )
	{
		mouseIsIn = YES;
		
		NSImage	*curImage = [[self image] retain];
		[super setImage:TCM_altImage];
		
		[TCM_altImage release];
		TCM_altImage = curImage;
	}
}


- (void)mouseExited:(NSEvent*)theEvent
{
	if ( [self isEnabled] )
	{
		mouseIsIn = NO;
		
		NSImage	*curImage = [[self image] retain];
		[super setImage:TCM_altImage];
		
		[TCM_altImage release];
		TCM_altImage = curImage;
	}
}


- (void)resetCursorRects 
{
	[self removeTrackingRect:trackingTag];
	
	trackingTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}

@end
