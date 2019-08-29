//  GutterRulerView.h
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Mon May 05 2003.

#import <AppKit/AppKit.h>
#import "FoldableTextStorage.h"

@interface NSBezierPath (BezierPathGutterRulerViewAdditions)
+ (NSBezierPath *)trianglePathInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge;
+ (void)fillTriangleInRect:(NSRect)aRect arrowPoint:(NSRectEdge)anEdge;
@end


@interface GutterRulerView : NSRulerView {
	NSPoint I_lastMouseDownPoint;
}

@property (nonatomic) BOOL suspendDrawing;

@end
