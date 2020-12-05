//  SEEAvatarImageView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 10.04.14.

#import "SEEAvatarImageView.h"
#import "NSImageTCMAdditions.h"

@interface SEEAvatarImageView ()
@property (nonatomic, strong) NSTrackingArea *hoverTrackingArea;
@property (nonatomic) BOOL isHovering;
@end

@implementation SEEAvatarImageView

static void * const SEEAvatarRedrawObservationContext = (void *)&SEEAvatarRedrawObservationContext;

+ (void)initialize {
	if (self == [SEEAvatarImageView class]) {
		[self exposeBinding:@"borderColor"];
		[self exposeBinding:@"image"];
		[self exposeBinding:@"initials"];
	}
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.borderColor = [NSColor lightGrayColor];
		self.initials = @"M E";
		
		[self registerKVO];
    }
    return self;
}

- (void)dealloc {
    [self unregisterKVO];
}


#pragma mark - KVO

- (void)registerKVO {
	[self addObserver:self forKeyPath:@"borderColor" options:0 context:SEEAvatarRedrawObservationContext];
	[self addObserver:self forKeyPath:@"image" options:0 context:SEEAvatarRedrawObservationContext];
	[self addObserver:self forKeyPath:@"initials" options:0 context:SEEAvatarRedrawObservationContext];
}

- (void)unregisterKVO {
	[self removeObserver:self forKeyPath:@"borderColor" context:SEEAvatarRedrawObservationContext];
	[self removeObserver:self forKeyPath:@"image" context:SEEAvatarRedrawObservationContext];
	[self removeObserver:self forKeyPath:@"initials" context:SEEAvatarRedrawObservationContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == SEEAvatarRedrawObservationContext) {
        [self setNeedsDisplay:YES];

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

	NSRect bounds = self.bounds;
	CGFloat borderWidth = NSWidth(bounds) / 20.0;
	CGFloat borderInset = ceil(borderWidth / 2.0);
	NSRect drawingRect = NSInsetRect(bounds, borderWidth/2.0, borderWidth/2.0);
	NSRect imageRect = [self centerScanRect:drawingRect];

	NSBezierPath *borderPath = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(imageRect,borderInset,borderInset)];
	[borderPath setLineWidth:borderWidth];

	NSColor *borderColor = self.borderColor;
	CGFloat saturation = 0.35;
	NSColor *backgroundColor = [[NSColor whiteColor] blendedColorWithFraction:saturation ofColor:borderColor];
	
	// draw the background
	[backgroundColor set];
	[borderPath fill];

	//draw the image clipped
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[borderPath setClip];

	NSImage *image = self.image;
	if (image) {
		[image drawInRect:imageRect
				 fromRect:NSZeroRect
				operation:NSCompositingOperationSourceOver
				 fraction:1.0
		   respectFlipped:YES
					hints:nil];
	} else {
		// draw placeholder image
		image = [NSImage unknownUserImageWithSize:imageRect.size initials:self.initials];
		[image drawInRect:imageRect
				 fromRect:NSZeroRect
				operation:NSCompositingOperationSourceOver
				 fraction:1.0
		   respectFlipped:YES
					hints:nil];
	}

	if (self.isHovering) {
		[[NSGraphicsContext currentContext] saveGraphicsState]; {
			// background
			[[NSColor colorWithWhite:0.0 alpha:0.5] set];
			[borderPath fill];
			
			// text
			if (self.hoverString) {
				NSShadow *textShadow = [[NSShadow alloc] init];
				textShadow.shadowBlurRadius = 5;
				textShadow.shadowColor = [NSColor colorWithWhite:0 alpha:0.8];
				textShadow.shadowOffset = NSMakeSize(0.0, -1.0);
				
				NSString *hoverString = self.hoverString;
				CGFloat inset = 10.;
				CGFloat maxFontSize = 16;
				
				NSFont *font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
				NSSize size = [hoverString sizeWithAttributes:@{ NSFontAttributeName : font}];
				NSSize insetSize = CGSizeMake(NSWidth(imageRect) - 2*inset, NSHeight(imageRect) - 2*inset);
				CGFloat scale = MIN( insetSize.width/size.width, insetSize.height/size.height );
				CGFloat fontSize = MIN(font.pointSize * scale, maxFontSize);
				font = [NSFont fontWithName:font.fontName size:fontSize];
				
				NSDictionary *stringAttributes = @{
												   NSFontAttributeName: font,
												   NSForegroundColorAttributeName: [NSColor whiteColor],
												   NSShadowAttributeName: textShadow
												   };
				
				NSSize textSize = [hoverString sizeWithAttributes:stringAttributes];
				NSRect textBounds = [hoverString boundingRectWithSize:textSize options:0 attributes:stringAttributes];
				
				NSRect textRect = NSMakeRect(NSMidX(imageRect) - NSWidth(textBounds) / 2.0,
											 NSMidY(imageRect) - NSHeight(textBounds) / 2.0 + 4.,
											 NSWidth(textBounds),
											 NSHeight(textBounds));
				
				textRect = [self centerScanRect:textRect];
				
				[hoverString drawWithRect:textRect
								  options:0
							   attributes:stringAttributes];
				
			}
		}[[NSGraphicsContext currentContext] restoreGraphicsState];
	}

	[[NSGraphicsContext currentContext] restoreGraphicsState];

	// draw the border
	[borderColor set];
	[borderPath stroke];
	
}


#pragma mark - Overrides

- (BOOL)isOpaque {
	return NO;
}

#pragma mark - Hover Image
- (void)enableHoverImage {

	NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect;

    NSPoint mouseLocationInBounds = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
	BOOL mouseIsInside = NSMouseInRect(mouseLocationInBounds, self.bounds, self.isFlipped);
    if (mouseIsInside) {
        options |= NSTrackingAssumeInside;
    }

	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
																options:options
																  owner:self
															   userInfo:nil];
	self.hoverTrackingArea = trackingArea;
	[self addTrackingArea:trackingArea];
}

- (void)disableHoverImage {
	self.isHovering = NO;
	[self removeTrackingArea:self.hoverTrackingArea];
	self.hoverTrackingArea = nil;
}

- (void)mouseEntered:(NSEvent *)anEvent {
	if (!self.isHovering) {
		[self setNeedsDisplay:YES];
	}
	self.isHovering = YES;
}

- (void)mouseExited:(NSEvent *)anEvent {
	if (self.isHovering) {
		[self setNeedsDisplay:YES];
	}
	self.isHovering = NO;
}

@end
