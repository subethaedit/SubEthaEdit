//
//  NSBezierPath_AMAdditons.m
//  PlateControl
//
//  Created by Andreas on Sun Jan 18 2004.
//  Copyright (c) 2004 Andreas Mayer. All rights reserved.
//
//	2005-05-23	Andreas Mayer
//	- added -appendBezierPathWithTriangleInRect:orientation: and +bezierPathWithTriangleInRect:orientation:


#import "NSBezierPath_AMAdditons.h"


@implementation NSBezierPath (AMAdditons)

+ (NSBezierPath *)bezierPathWithPlateInRect:(NSRect)rect
{
	NSBezierPath *result = [[NSBezierPath alloc] init];
	[result appendBezierPathWithPlateInRect:rect];
	return [result autorelease];
}

- (void)appendBezierPathWithPlateInRect:(NSRect)rect
{
	if (rect.size.height > 0) {
		float xoff = rect.origin.x;
		float yoff = rect.origin.y;
		float radius = rect.size.height/2.0;
		NSPoint point4 = NSMakePoint(xoff+radius, yoff+rect.size.height);
		NSPoint center1 = NSMakePoint(xoff+radius, yoff+radius);
		NSPoint center2 = NSMakePoint(xoff+rect.size.width-radius, yoff+radius);
		[self moveToPoint:point4];
		[self appendBezierPathWithArcWithCenter:center1 radius:radius startAngle:90.0 endAngle:270.0];
		[self appendBezierPathWithArcWithCenter:center2 radius:radius startAngle:270.0 endAngle:90.0];
		[self closePath];
	}
}


+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius
{
	NSBezierPath *result = [[[NSBezierPath alloc] init] autorelease];
	[result appendBezierPathWithRoundedRect:rect cornerRadius:radius];
	return result;
}

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius
{
	if (rect.size.height > 0) {
		float xoff = rect.origin.x;
		float yoff = rect.origin.y;
		NSPoint startpoint = NSMakePoint(xoff, yoff+radius);
		NSPoint center1 = NSMakePoint(xoff+radius, yoff+radius);
		NSPoint center2 = NSMakePoint(xoff+rect.size.width-radius, yoff+radius);
		NSPoint center3 = NSMakePoint(xoff+rect.size.width-radius, yoff+rect.size.height-radius);
		NSPoint center4 = NSMakePoint(xoff+radius, yoff+rect.size.height-radius);
		[self moveToPoint:startpoint];
		[self appendBezierPathWithArcWithCenter:center1 radius:radius startAngle:180.0 endAngle:270.0];
		[self appendBezierPathWithArcWithCenter:center2 radius:radius startAngle:270.0 endAngle:360.0];
		[self appendBezierPathWithArcWithCenter:center3 radius:radius startAngle:360.0 endAngle:90.0];
		[self appendBezierPathWithArcWithCenter:center4 radius:radius startAngle:90.0 endAngle:180.0];
		[self closePath];
	}
}

+ (NSBezierPath *)bezierPathWithTriangleInRect:(NSRect)aRect orientation:(AMTriangleOrientation)orientation
{
	NSBezierPath *result = [[[NSBezierPath alloc] init] autorelease];
	[result appendBezierPathWithTriangleInRect:aRect orientation:orientation];
	return result;
}

- (void)appendBezierPathWithTriangleInRect:(NSRect)aRect orientation:(AMTriangleOrientation)orientation
{	
	NSPoint a, b, c;
	switch (orientation)	{
		case AMTriangleUp:
		{
			a = NSMakePoint(NSMinX(aRect), NSMinY(aRect));
			b = NSMakePoint((NSMinX(aRect) + NSMaxX(aRect)) / 2, NSMaxY(aRect));
			c = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
			break;
		}
			
		case AMTriangleDown:
		{
			a = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
			c = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
			b = NSMakePoint((NSMinX(aRect) + NSMaxX(aRect)) / 2, NSMinY(aRect));
			break;
		}
			
		case AMTriangleLeft:
		{
			a = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
			b = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
			c = NSMakePoint(NSMinX(aRect), (NSMinY(aRect) + NSMaxY(aRect)) / 2);
			break;
		}
			
		default : // case AMTriangleRight:
		{
			a = NSMakePoint(NSMinX(aRect), NSMinY(aRect));
			b = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
			c = NSMakePoint(NSMaxX(aRect), (NSMinY(aRect) + NSMaxY(aRect)) / 2);
			break;
		}
	}
	
	[self moveToPoint:a];
	[self lineToPoint:b];
	[self lineToPoint:c];
	[self closePath];
}


@end
