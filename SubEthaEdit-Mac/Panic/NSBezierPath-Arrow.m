#import "NSBezierPath-Arrow.h"


@implementation NSBezierPath (Arrow)

+ (NSBezierPath*)arrowInRect:(NSRect)aRect pointEdge:(NSRectEdge)edge
{
	NSBezierPath *newPath = [NSBezierPath bezierPath];
	
	switch ( edge )
	{
		default:
		case NSMaxXEdge:

			// points right - left edge
			[newPath moveToPoint:NSMakePoint(0, aRect.size.height)];
			
			[newPath lineToPoint:NSMakePoint(0, 0)];
		
			// bottom edge
			[newPath lineToPoint:NSMakePoint(aRect.size.width, aRect.size.height / 2)];
		
			// top edge
			[newPath lineToPoint:NSMakePoint(0, aRect.size.height)];
			
			break;
			
		case NSMinYEdge:
			
			// points down - top edge
			[newPath moveToPoint:NSMakePoint(0, aRect.size.height)];

			[newPath lineToPoint:NSMakePoint(aRect.size.width, aRect.size.height)];
		
			// right edge 
			[newPath lineToPoint:NSMakePoint(aRect.size.width / 2, 0)];
			
			// left edge
			[newPath lineToPoint:NSMakePoint(0, aRect.size.height)];
			
			break;
	
		case NSMinXEdge:
			
			// points left - top edge
			[newPath moveToPoint:NSMakePoint(aRect.size.width, aRect.size.height)];
			
			[newPath lineToPoint:NSMakePoint(0, aRect.size.height / 2)];
			
			// bottom edge
			[newPath lineToPoint:NSMakePoint(aRect.size.width, 0)];
			
			// right edge
			[newPath lineToPoint:NSMakePoint(aRect.size.width, aRect.size.height)];
			
			break;
	
		case NSMaxYEdge:
			
			// points up - top edge
			[newPath moveToPoint:NSMakePoint(aRect.size.width / 2, aRect.size.height)];
			
			// left edge
			[newPath lineToPoint:NSMakePoint(0, 0)];
			
			// bottom edge
			[newPath lineToPoint:NSMakePoint(aRect.size.width, 0)];
			
			// right edge
			[newPath lineToPoint:NSMakePoint(aRect.size.width / 2, aRect.size.height)];
			
			break;
	}
	
	[newPath closePath];
	
	
	if ( !NSEqualPoints(aRect.origin, NSZeroPoint) )
	{
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:aRect.origin.x yBy:aRect.origin.y];
		
		[newPath transformUsingAffineTransform:transform];
	}
	
	return newPath;
}


@end
